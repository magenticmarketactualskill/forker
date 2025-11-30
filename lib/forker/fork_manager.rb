# frozen_string_literal: true

module Forker
  class ForkManager
    def initialize(base_path = Dir.pwd)
      @storage = Storage.new(base_path)
      @github = GitHubClient.new
    end

    def fork_repository(repo_url, account)
      result = @github.fork_repository(repo_url, account)
      
      # Save fork information
      @storage.save_fork_info(result[:name], result)
      
      result
    end

    def list_forks(account)
      forks = @github.list_user_forks(account)
      
      # Save each fork's information
      forks.each do |fork|
        @storage.save_fork_info(fork[:name], fork)
      end
      
      forks
    end

    def list_gemfile_forks
      gemfile_path = File.join(Dir.pwd, "Gemfile")
      unless File.exist?(gemfile_path)
        raise Error, "Gemfile not found in current directory"
      end

      gemfile_content = File.read(gemfile_path)
      forks = []

      # Parse git-based gems
      gemfile_content.scan(/gem\s+['"]([^'"]+)['"]\s*,\s*git:\s*['"]([^'"]+)['"]/) do |gem_name, git_url|
        next unless git_url.include?("github.com")
        
        fork_info = check_if_fork(git_url)
        if fork_info
          forks << {
            name: gem_name,
            url: git_url,
            type: "git",
            root_url: fork_info[:root_url],
            description: fork_info[:description],
            updated_at: fork_info[:updated_at]
          }
          
          # Save fork information
          @storage.save_fork_info(gem_name, fork_info.merge(fork_url: git_url))
        end
      end

      # Parse path-based gems (check if they're git repos with remotes)
      gemfile_content.scan(/gem\s+['"]([^'"]+)['"]\s*,\s*path:\s*['"]([^'"]+)['"]/) do |gem_name, path|
        full_path = File.expand_path(path, Dir.pwd)
        next unless File.directory?(File.join(full_path, ".git"))
        
        # Get the remote URL
        remote_url = get_git_remote_url(full_path)
        next unless remote_url && remote_url.include?("github.com")
        
        fork_info = check_if_fork(remote_url)
        if fork_info
          forks << {
            name: gem_name,
            url: remote_url,
            type: "path (vendored)",
            root_url: fork_info[:root_url],
            description: fork_info[:description],
            updated_at: fork_info[:updated_at]
          }
          
          # Save fork information
          @storage.save_fork_info(gem_name, fork_info.merge(fork_url: remote_url))
        end
      end

      forks
    end

    def fork_statuses
      tracked_gems = @storage.list_tracked_gems
      
      tracked_gems.map do |gem_name|
        info = @storage.load_fork_info(gem_name)
        next unless info

        # Get comparison with root if available
        status = {
          name: gem_name,
          fork_url: info[:fork_url] || info[:url],
          root_url: info[:root_url],
          updated_at: info[:updated_at]
        }

        # Try to get ahead/behind information if we have both fork and root
        if info[:owner] && info[:name] && info[:root_url]
          begin
            root_owner, root_repo = parse_repo_from_url(info[:root_url])
            comparison = @github.compare_commits(
              info[:owner],
              info[:name],
              "#{root_owner}:main",
              "main"
            )
            status[:ahead_by] = comparison[:ahead_by]
            status[:behind_by] = comparison[:behind_by]
          rescue GitHubError
            # Comparison failed, skip it
          end
        end

        status
      end.compact
    end

    def find_peers
      tracked_gems = @storage.list_tracked_gems
      
      tracked_gems.map do |gem_name|
        info = @storage.load_fork_info(gem_name)
        next unless info && info[:root_url]

        # Get all forks of the root repository
        root_owner, root_repo = parse_repo_from_url(info[:root_url])
        peers = @github.list_forks(root_owner, root_repo)
        
        # Filter out the current fork
        current_fork_url = info[:fork_url] || info[:url]
        peers = peers.reject { |peer| peer[:url] == current_fork_url }
        
        # Save peers information
        @storage.save_peers(gem_name, peers)
        
        {
          name: gem_name,
          root_url: info[:root_url],
          peers: peers
        }
      end.compact
    end

    def list_pull_requests
      tracked_gems = @storage.list_tracked_gems
      
      tracked_gems.map do |gem_name|
        info = @storage.load_fork_info(gem_name)
        next unless info

        # Get PRs for the fork
        prs = if info[:owner] && info[:name]
                @github.list_pull_requests(info[:owner], info[:name])
              else
                []
              end

        # Also get PRs for the root repository if available
        if info[:root_url]
          begin
            root_owner, root_repo = parse_repo_from_url(info[:root_url])
            root_prs = @github.list_pull_requests(root_owner, root_repo)
            prs += root_prs
          rescue GitHubError
            # Root PRs fetch failed, continue with fork PRs only
          end
        end

        # Save PRs information
        @storage.save_prs(gem_name, prs)
        
        {
          name: gem_name,
          prs: prs
        }
      end.compact
    end

    def most_active_forks
      tracked_gems = @storage.list_tracked_gems
      
      forks = tracked_gems.map do |gem_name|
        info = @storage.load_fork_info(gem_name)
        next unless info && info[:root_url]

        # Get all forks and sort by activity
        root_owner, root_repo = parse_repo_from_url(info[:root_url])
        all_forks = @github.list_forks(root_owner, root_repo)
        
        # Add the root repository itself
        root_info = @github.get_repository_info("#{root_owner}/#{root_repo}")
        all_forks << {
          owner: root_owner,
          name: root_repo,
          url: root_info[:url],
          updated_at: root_info[:updated_at]
        }

        all_forks
      end.flatten.compact

      # Sort by updated_at (most recent first)
      forks.sort_by { |fork| fork[:updated_at] }.reverse.uniq { |fork| fork[:url] }.map do |fork|
        {
          name: fork[:name],
          url: fork[:url],
          owner: fork[:owner],
          updated_at: fork[:updated_at],
          root_url: nil # Could be enhanced to track this
        }
      end
    end

    private

    def check_if_fork(repo_url)
      owner, repo = parse_repo_from_url(repo_url)
      repo_info = @github.get_repository_info("#{owner}/#{repo}")
      
      if repo_info[:is_fork]
        # It's a fork, find the root
        root_info = @github.find_root_repository(owner, repo)
        {
          fork: true,
          root_url: root_info[:url],
          description: repo_info[:description],
          updated_at: repo_info[:updated_at],
          owner: owner,
          name: repo
        }
      else
        nil
      end
    rescue GitHubError => e
      # If we can't check, assume it's not a fork
      nil
    end

    def get_git_remote_url(path)
      Dir.chdir(path) do
        remote_url = `git config --get remote.origin.url`.strip
        return nil if remote_url.empty?
        remote_url
      end
    rescue StandardError
      nil
    end

    def parse_repo_from_url(url)
      # Handle various GitHub URL formats
      if url.include?("github.com")
        match = url.match(%r{github\.com[:/]([^/]+)/([^/\.]+)})
        return [match[1], match[2]] if match
      elsif url.include?("/")
        parts = url.split("/")
        return [parts[-2], parts[-1].gsub(".git", "")]
      end

      raise GitHubError, "Invalid GitHub repository URL: #{url}"
    end
  end
end
