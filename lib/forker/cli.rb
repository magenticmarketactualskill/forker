# frozen_string_literal: true

require "thor"

module Forker
  class CLI < Thor
    def self.exit_on_failure?
      true
    end

    desc "list --account=ACCOUNT", "List all forks for a GitHub account"
    option :account, type: :string, required: true, desc: "GitHub account URL or username"
    def list
      manager = ForkManager.new
      forks = manager.list_forks(options[:account])
      
      if forks.empty?
        puts "No forks found for account: #{options[:account]}"
      else
        puts "\nForks for #{options[:account]}:"
        puts "-" * 80
        forks.each do |fork|
          puts "\n#{fork[:name]}"
          puts "  URL: #{fork[:url]}"
          puts "  Root: #{fork[:root_url]}" if fork[:root_url]
          puts "  Description: #{fork[:description]}" if fork[:description]
          puts "  Updated: #{fork[:updated_at]}"
        end
        puts "\nTotal forks: #{forks.size}"
      end
    rescue Error => e
      puts "Error: #{e.message}"
      exit 1
    end

    desc "fork --url=URL --account=ACCOUNT", "Fork a repository on GitHub"
    option :url, type: :string, required: true, desc: "Repository URL to fork"
    option :account, type: :string, required: true, desc: "GitHub account to fork to"
    def fork
      manager = ForkManager.new
      result = manager.fork_repository(options[:url], options[:account])
      
      puts "\nSuccessfully forked repository!"
      puts "  Original: #{result[:original_url]}"
      puts "  Fork: #{result[:fork_url]}"
      puts "  Root: #{result[:root_url]}" if result[:root_url]
    rescue Error => e
      puts "Error: #{e.message}"
      exit 1
    end

    desc "status", "Show status of tracked forks"
    def status
      manager = ForkManager.new
      statuses = manager.fork_statuses
      
      if statuses.empty?
        puts "No tracked forks found in .forker directory"
      else
        puts "\nFork Status:"
        puts "-" * 80
        statuses.each do |status|
          puts "\n#{status[:name]}"
          puts "  Fork: #{status[:fork_url]}"
          puts "  Root: #{status[:root_url]}" if status[:root_url]
          puts "  Commits ahead: #{status[:ahead_by]}" if status[:ahead_by]
          puts "  Commits behind: #{status[:behind_by]}" if status[:behind_by]
          puts "  Last updated: #{status[:updated_at]}"
        end
        puts "\nTotal tracked forks: #{statuses.size}"
      end
    rescue Error => e
      puts "Error: #{e.message}"
      exit 1
    end

    desc "peers", "List other forks of the same repositories"
    def peers
      manager = ForkManager.new
      peers_data = manager.find_peers
      
      if peers_data.empty?
        puts "No tracked forks found"
      else
        puts "\nPeer Forks:"
        puts "-" * 80
        peers_data.each do |data|
          puts "\n#{data[:name]} (#{data[:root_url]})"
          if data[:peers].empty?
            puts "  No other forks found"
          else
            puts "  Other forks (#{data[:peers].size}):"
            data[:peers].each do |peer|
              puts "    - #{peer[:owner]}/#{peer[:name]} (updated: #{peer[:updated_at]})"
            end
          end
        end
      end
    rescue Error => e
      puts "Error: #{e.message}"
      exit 1
    end

    desc "prs", "List pull requests across fork network"
    def prs
      manager = ForkManager.new
      prs_data = manager.list_pull_requests
      
      if prs_data.empty?
        puts "No tracked forks found"
      else
        puts "\nPull Requests:"
        puts "-" * 80
        prs_data.each do |data|
          puts "\n#{data[:name]}"
          if data[:prs].empty?
            puts "  No open pull requests"
          else
            puts "  Open PRs (#{data[:prs].size}):"
            data[:prs].each do |pr|
              puts "    ##{pr[:number]}: #{pr[:title]}"
              puts "      Author: #{pr[:author]} | State: #{pr[:state]} | Created: #{pr[:created_at]}"
            end
          end
        end
      end
    rescue Error => e
      puts "Error: #{e.message}"
      exit 1
    end

    desc "active", "Show most recently active forks"
    def active
      manager = ForkManager.new
      active_forks = manager.most_active_forks
      
      if active_forks.empty?
        puts "No tracked forks found"
      else
        puts "\nMost Active Forks:"
        puts "-" * 80
        active_forks.each_with_index do |fork, index|
          puts "\n#{index + 1}. #{fork[:name]}"
          puts "   URL: #{fork[:url]}"
          puts "   Root: #{fork[:root_url]}" if fork[:root_url]
          puts "   Last activity: #{fork[:updated_at]}"
          puts "   Recent commits: #{fork[:recent_commits]}" if fork[:recent_commits]
        end
      end
    rescue Error => e
      puts "Error: #{e.message}"
      exit 1
    end
  end
end
