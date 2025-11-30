# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe Forker::Storage do
  let(:temp_dir) { Dir.mktmpdir }
  let(:storage) { described_class.new(temp_dir) }

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe "#ensure_forker_directory" do
    it "creates .forker directory if it doesn't exist" do
      forker_path = storage.ensure_forker_directory
      expect(Dir.exist?(forker_path)).to be true
      expect(File.basename(forker_path)).to eq(".forker")
    end

    it "returns existing .forker directory if it exists" do
      first_call = storage.ensure_forker_directory
      second_call = storage.ensure_forker_directory
      expect(first_call).to eq(second_call)
    end
  end

  describe "#gem_directory" do
    it "creates a directory for the gem" do
      gem_dir = storage.gem_directory("test_gem")
      expect(Dir.exist?(gem_dir)).to be true
      expect(gem_dir).to include("test_gem")
    end

    it "sanitizes gem names" do
      gem_dir = storage.gem_directory("test/gem@123")
      expect(File.basename(gem_dir)).to eq("test_gem_123")
    end
  end

  describe "#save_fork_info and #load_fork_info" do
    let(:fork_data) do
      {
        name: "test_gem",
        url: "https://github.com/user/test_gem",
        root_url: "https://github.com/original/test_gem",
        updated_at: "2024-01-01"
      }
    end

    it "saves and loads fork information" do
      storage.save_fork_info("test_gem", fork_data)
      loaded_data = storage.load_fork_info("test_gem")
      
      expect(loaded_data[:name]).to eq(fork_data[:name])
      expect(loaded_data[:url]).to eq(fork_data[:url])
      expect(loaded_data[:root_url]).to eq(fork_data[:root_url])
    end

    it "returns nil for non-existent fork info" do
      expect(storage.load_fork_info("nonexistent")).to be_nil
    end
  end

  describe "#save_peers and #load_peers" do
    let(:peers_data) do
      [
        { owner: "user1", name: "fork1", url: "https://github.com/user1/fork1" },
        { owner: "user2", name: "fork2", url: "https://github.com/user2/fork2" }
      ]
    end

    it "saves and loads peers information" do
      storage.save_peers("test_gem", peers_data)
      loaded_peers = storage.load_peers("test_gem")
      
      expect(loaded_peers.size).to eq(2)
      expect(loaded_peers.first[:owner]).to eq("user1")
    end

    it "returns empty array for non-existent peers" do
      expect(storage.load_peers("nonexistent")).to eq([])
    end
  end

  describe "#save_prs and #load_prs" do
    let(:prs_data) do
      [
        { number: 1, title: "Fix bug", author: "user1", state: "open" },
        { number: 2, title: "Add feature", author: "user2", state: "closed" }
      ]
    end

    it "saves and loads pull requests information" do
      storage.save_prs("test_gem", prs_data)
      loaded_prs = storage.load_prs("test_gem")
      
      expect(loaded_prs.size).to eq(2)
      expect(loaded_prs.first[:title]).to eq("Fix bug")
    end

    it "returns empty array for non-existent PRs" do
      expect(storage.load_prs("nonexistent")).to eq([])
    end
  end

  describe "#list_tracked_gems" do
    it "returns empty array when no gems are tracked" do
      expect(storage.list_tracked_gems).to eq([])
    end

    it "lists all tracked gems" do
      storage.save_fork_info("gem1", { name: "gem1" })
      storage.save_fork_info("gem2", { name: "gem2" })
      
      tracked = storage.list_tracked_gems
      expect(tracked.size).to eq(2)
      expect(tracked).to include("gem1", "gem2")
    end
  end

  describe "#delete_gem_data" do
    it "deletes gem directory and all its contents" do
      storage.save_fork_info("test_gem", { name: "test_gem" })
      gem_dir = storage.gem_directory("test_gem")
      
      expect(Dir.exist?(gem_dir)).to be true
      
      storage.delete_gem_data("test_gem")
      
      expect(Dir.exist?(gem_dir)).to be false
    end
  end
end
