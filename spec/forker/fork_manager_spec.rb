# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe Forker::ForkManager do
  let(:temp_dir) { Dir.mktmpdir }
  let(:manager) { described_class.new(temp_dir) }
  let(:storage) { instance_double(Forker::Storage) }
  let(:github) { instance_double(Forker::GitHubClient) }

  before do
    allow(Forker::Storage).to receive(:new).and_return(storage)
    allow(Forker::GitHubClient).to receive(:new).and_return(github)
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe "#fork_repository" do
    let(:fork_result) do
      {
        original_url: "https://github.com/original/repo",
        fork_url: "https://github.com/user/repo",
        root_url: "https://github.com/original/repo",
        name: "repo",
        owner: "user",
        created_at: Time.now.to_s
      }
    end

    before do
      allow(github).to receive(:fork_repository).and_return(fork_result)
      allow(storage).to receive(:save_fork_info)
    end

    it "forks a repository and saves the information" do
      result = manager.fork_repository("https://github.com/original/repo", "user")
      
      expect(result[:name]).to eq("repo")
      expect(result[:fork_url]).to eq("https://github.com/user/repo")
      expect(storage).to have_received(:save_fork_info).with("repo", fork_result)
    end
  end

  describe "#list_forks" do
    let(:forks_data) do
      [
        {
          name: "fork1",
          url: "https://github.com/user/fork1",
          description: "First fork",
          updated_at: "2024-01-01",
          root_url: "https://github.com/original/fork1"
        },
        {
          name: "fork2",
          url: "https://github.com/user/fork2",
          description: "Second fork",
          updated_at: "2024-01-02",
          root_url: "https://github.com/original/fork2"
        }
      ]
    end

    before do
      allow(github).to receive(:list_user_forks).and_return(forks_data)
      allow(storage).to receive(:save_fork_info)
    end

    it "lists forks and saves their information" do
      forks = manager.list_forks("user")
      
      expect(forks.size).to eq(2)
      expect(forks.first[:name]).to eq("fork1")
      expect(storage).to have_received(:save_fork_info).twice
    end
  end

  describe "#fork_statuses" do
    before do
      allow(storage).to receive(:list_tracked_gems).and_return(["gem1", "gem2"])
      allow(storage).to receive(:load_fork_info).with("gem1").and_return(
        {
          name: "gem1",
          fork_url: "https://github.com/user/gem1",
          root_url: "https://github.com/original/gem1",
          updated_at: "2024-01-01",
          owner: "user"
        }
      )
      allow(storage).to receive(:load_fork_info).with("gem2").and_return(
        {
          name: "gem2",
          url: "https://github.com/user/gem2",
          root_url: "https://github.com/original/gem2",
          updated_at: "2024-01-02",
          owner: "user"
        }
      )
    end

    it "returns status of tracked forks" do
      statuses = manager.fork_statuses
      
      expect(statuses.size).to eq(2)
      expect(statuses.first[:name]).to eq("gem1")
      expect(statuses.last[:name]).to eq("gem2")
    end
  end

  describe "#find_peers" do
    before do
      allow(storage).to receive(:list_tracked_gems).and_return(["gem1"])
      allow(storage).to receive(:load_fork_info).with("gem1").and_return(
        {
          name: "gem1",
          fork_url: "https://github.com/user/gem1",
          root_url: "https://github.com/original/gem1",
          url: "https://github.com/user/gem1"
        }
      )
      
      peers_data = [
        { owner: "user1", name: "gem1", url: "https://github.com/user1/gem1" },
        { owner: "user2", name: "gem1", url: "https://github.com/user2/gem1" },
        { owner: "user", name: "gem1", url: "https://github.com/user/gem1" } # Current fork
      ]
      
      allow(github).to receive(:list_forks).and_return(peers_data)
      allow(storage).to receive(:save_peers)
    end

    it "finds peers and filters out current fork" do
      peers = manager.find_peers
      
      expect(peers.size).to eq(1)
      expect(peers.first[:peers].size).to eq(2) # Excludes current fork
      expect(peers.first[:peers].map { |p| p[:owner] }).not_to include("user")
    end
  end

  describe "#list_pull_requests" do
    before do
      allow(storage).to receive(:list_tracked_gems).and_return(["gem1"])
      allow(storage).to receive(:load_fork_info).with("gem1").and_return(
        {
          name: "gem1",
          owner: "user",
          root_url: "https://github.com/original/gem1"
        }
      )
      
      fork_prs = [
        { number: 1, title: "Fork PR", author: "user", state: "open", created_at: "2024-01-01" }
      ]
      
      root_prs = [
        { number: 2, title: "Root PR", author: "maintainer", state: "open", created_at: "2024-01-02" }
      ]
      
      allow(github).to receive(:list_pull_requests).with("user", "gem1").and_return(fork_prs)
      allow(github).to receive(:list_pull_requests).with("original", "gem1").and_return(root_prs)
      allow(storage).to receive(:save_prs)
    end

    it "lists pull requests from fork and root" do
      prs = manager.list_pull_requests
      
      expect(prs.size).to eq(1)
      expect(prs.first[:prs].size).to eq(2) # Fork + Root PRs
    end
  end

  describe "#most_active_forks" do
    before do
      allow(storage).to receive(:list_tracked_gems).and_return(["gem1"])
      allow(storage).to receive(:load_fork_info).with("gem1").and_return(
        {
          name: "gem1",
          root_url: "https://github.com/original/gem1"
        }
      )
      
      forks_data = [
        { owner: "user1", name: "gem1", url: "https://github.com/user1/gem1", updated_at: "2024-01-01" },
        { owner: "user2", name: "gem1", url: "https://github.com/user2/gem1", updated_at: "2024-01-03" }
      ]
      
      root_info = {
        url: "https://github.com/original/gem1",
        updated_at: "2024-01-02"
      }
      
      allow(github).to receive(:list_forks).and_return(forks_data)
      allow(github).to receive(:get_repository_info).and_return(root_info)
    end

    it "returns forks sorted by activity" do
      active = manager.most_active_forks
      
      expect(active.size).to eq(3) # 2 forks + 1 root
      expect(active.first[:updated_at]).to eq("2024-01-03") # Most recent first
    end
  end
end
