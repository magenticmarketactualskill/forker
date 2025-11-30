# frozen_string_literal: true

require "json"
require "open3"

module Forker
  class GitHubClient
    def initialize
      check_gh_installed
    end

    def fork_repository(repo_url, account)
      owner, repo = parse_repo_url(repo_url)
      
      # Fork the repository
      output, status = run_gh_command("repo fork #{owner}/#{repo} --clone=false --remote=false")
      raise GitHubError, "Failed to fork repository: #{output}" unless status.success?

      # Get fork information
      fork_info = get_repository_info("#{account}/#{repo}")
      
      # Get root repository
      root_info = find_root_repository(owner, repo)
      
      {
        original_url: repo_url,
        fork_url: fork_info[:url],
        root_url: root_info[:url],
        name: repo,
        owner: account,
        created_at: Time.now.to_s
      }
    end

    def list_user_forks(account)
      # Extract username from account (handle both URLs and usernames)
      username = account.split("/").last
      
      output, status = run_gh_command("repo list #{username} --fork --json name,url,description,updatedAt,parent --limit 100")
      raise GitHubError, "Failed to list forks: #{output}" unless status.success?

      repos = JSON.parse(output, symbolize_names: true)
      
      repos.map do |repo|
        {
          name: repo[:name],
          url: repo[:url],
          description: repo[:description],
          updated_at: repo[:updatedAt],
          root_url: repo[:parent] ? find_root_from_parent(repo[:parent]) : nil
        }
      end
    rescue JSON::ParserError => e
      raise GitHubError, "Failed to parse GitHub response: #{e.message}"
    end

    def get_repository_info(full_name)
      output, status = run_gh_command("repo view #{full_name} --json name,url,description,updatedAt,parent,isFork")
      raise GitHubError, "Failed to get repository info: #{output}" unless status.success?

      repo = JSON.parse(output, symbolize_names: true)
      
      {
        name: repo[:name],
        url: repo[:url],
        description: repo[:description],
        updated_at: repo[:updatedAt],
        is_fork: repo[:isFork],
        parent_url: repo[:parent] ? repo[:parent][:url] : nil
      }
    rescue JSON::ParserError => e
      raise GitHubError, "Failed to parse repository info: #{e.message}"
    end

    def find_root_repository(owner, repo)
      current_owner = owner
      current_repo = repo
      visited = Set.new

      loop do
        full_name = "#{current_owner}/#{current_repo}"
        break if visited.include?(full_name) # Prevent infinite loops

        visited.add(full_name)
        
        info = get_repository_info(full_name)
        
        if !info[:is_fork] || info[:parent_url].nil?
          return {
            url: info[:url],
            owner: current_owner,
            name: current_repo
          }
        end

        # Move to parent
        parent_owner, parent_repo = parse_repo_url(info[:parent_url])
        current_owner = parent_owner
        current_repo = parent_repo
      end

      # Fallback if we hit a cycle
      { url: "https://github.com/#{owner}/#{repo}", owner: owner, name: repo }
    end

    def list_forks(owner, repo)
      output, status = run_gh_command("api repos/#{owner}/#{repo}/forks --paginate --jq '.[] | {owner: .owner.login, name: .name, url: .html_url, updated_at: .updated_at}'")
      
      return [] unless status.success?

      output.lines.map do |line|
        JSON.parse(line.strip, symbolize_names: true)
      end
    rescue JSON::ParserError
      []
    end

    def list_pull_requests(owner, repo)
      output, status = run_gh_command("pr list --repo #{owner}/#{repo} --json number,title,author,state,createdAt --limit 50")
      
      return [] unless status.success?

      prs = JSON.parse(output, symbolize_names: true)
      
      prs.map do |pr|
        {
          number: pr[:number],
          title: pr[:title],
          author: pr[:author][:login],
          state: pr[:state],
          created_at: pr[:createdAt]
        }
      end
    rescue JSON::ParserError
      []
    end

    def compare_commits(owner, repo, base, head)
      output, status = run_gh_command("api repos/#{owner}/#{repo}/compare/#{base}...#{head} --jq '{ahead_by: .ahead_by, behind_by: .behind_by}'")
      
      return { ahead_by: 0, behind_by: 0 } unless status.success?

      JSON.parse(output, symbolize_names: true)
    rescue JSON::ParserError
      { ahead_by: 0, behind_by: 0 }
    end

    private

    def check_gh_installed
      _, status = run_command("which gh")
      raise GitHubError, "GitHub CLI (gh) is not installed. Please install it from https://cli.github.com/" unless status.success?
    end

    def run_gh_command(command)
      run_command("gh #{command}")
    end

    def run_command(command)
      output, status = Open3.capture2e(command)
      [output.strip, status]
    end

    def parse_repo_url(url)
      # Handle various GitHub URL formats
      # https://github.com/owner/repo
      # https://github.com/owner/repo.git
      # git@github.com:owner/repo.git
      # owner/repo
      
      if url.include?("github.com")
        match = url.match(%r{github\.com[:/]([^/]+)/([^/\.]+)})
        return [match[1], match[2]] if match
      elsif url.include?("/")
        parts = url.split("/")
        return [parts[-2], parts[-1].gsub(".git", "")]
      end

      raise GitHubError, "Invalid GitHub repository URL: #{url}"
    end

    def find_root_from_parent(parent_info)
      return nil unless parent_info

      # Recursively find root
      if parent_info[:isFork] && parent_info[:parent]
        find_root_from_parent(parent_info[:parent])
      else
        parent_info[:url]
      end
    end
  end
end
