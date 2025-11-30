# frozen_string_literal: true

require "spec_helper"

RSpec.describe Forker::GitHubClient do
  let(:client) { described_class.new }

  describe "#initialize" do
    context "when gh is not installed" do
      before do
        allow(Open3).to receive(:capture2e).with("which gh").and_return(["", double(success?: false)])
      end

      it "raises an error" do
        expect { described_class.new }.to raise_error(Forker::GitHubError, /GitHub CLI.*not installed/)
      end
    end

    context "when gh is installed" do
      before do
        allow(Open3).to receive(:capture2e).with("which gh").and_return(["/usr/bin/gh", double(success?: true)])
      end

      it "does not raise an error" do
        expect { described_class.new }.not_to raise_error
      end
    end
  end

  describe "#parse_repo_url" do
    before do
      allow(Open3).to receive(:capture2e).with("which gh").and_return(["/usr/bin/gh", double(success?: true)])
    end

    it "parses HTTPS URLs" do
      owner, repo = client.send(:parse_repo_url, "https://github.com/owner/repo")
      expect(owner).to eq("owner")
      expect(repo).to eq("repo")
    end

    it "parses HTTPS URLs with .git extension" do
      owner, repo = client.send(:parse_repo_url, "https://github.com/owner/repo.git")
      expect(owner).to eq("owner")
      expect(repo).to eq("repo")
    end

    it "parses SSH URLs" do
      owner, repo = client.send(:parse_repo_url, "git@github.com:owner/repo.git")
      expect(owner).to eq("owner")
      expect(repo).to eq("repo")
    end

    it "parses short format" do
      owner, repo = client.send(:parse_repo_url, "owner/repo")
      expect(owner).to eq("owner")
      expect(repo).to eq("repo")
    end

    it "raises error for invalid URLs" do
      expect { client.send(:parse_repo_url, "invalid") }.to raise_error(Forker::GitHubError, /Invalid GitHub repository URL/)
    end
  end

  describe "#fork_repository" do
    before do
      allow(Open3).to receive(:capture2e).with("which gh").and_return(["/usr/bin/gh", double(success?: true)])
      
      # Mock fork command
      allow(Open3).to receive(:capture2e).with(/gh repo fork/).and_return(
        ["Forked successfully", double(success?: true)]
      )
      
      # Mock get repository info
      allow(client).to receive(:get_repository_info).with("testuser/testrepo").and_return(
        {
          name: "testrepo",
          url: "https://github.com/testuser/testrepo",
          description: "Test repository",
          updated_at: "2024-01-01",
          is_fork: true,
          parent_url: "https://github.com/original/testrepo"
        }
      )
      
      # Mock find root repository
      allow(client).to receive(:find_root_repository).and_return(
        {
          url: "https://github.com/original/testrepo",
          owner: "original",
          name: "testrepo"
        }
      )
    end

    it "forks a repository successfully" do
      result = client.fork_repository("https://github.com/original/testrepo", "testuser")
      
      expect(result[:name]).to eq("testrepo")
      expect(result[:fork_url]).to eq("https://github.com/testuser/testrepo")
      expect(result[:root_url]).to eq("https://github.com/original/testrepo")
    end
  end

  describe "#list_user_forks" do
    before do
      allow(Open3).to receive(:capture2e).with("which gh").and_return(["/usr/bin/gh", double(success?: true)])
      
      repos_json = [
        {
          name: "fork1",
          url: "https://github.com/user/fork1",
          description: "First fork",
          updatedAt: "2024-01-01",
          parent: { url: "https://github.com/original/fork1" }
        },
        {
          name: "fork2",
          url: "https://github.com/user/fork2",
          description: "Second fork",
          updatedAt: "2024-01-02",
          parent: { url: "https://github.com/original/fork2" }
        }
      ].to_json
      
      allow(Open3).to receive(:capture2e).with(/gh repo list/).and_return(
        [repos_json, double(success?: true)]
      )
      
      allow(client).to receive(:find_root_from_parent).and_return("https://github.com/original/fork1")
    end

    it "lists user forks" do
      forks = client.list_user_forks("testuser")
      
      expect(forks.size).to eq(2)
      expect(forks.first[:name]).to eq("fork1")
      expect(forks.last[:name]).to eq("fork2")
    end
  end

  describe "#list_forks" do
    before do
      allow(Open3).to receive(:capture2e).with("which gh").and_return(["/usr/bin/gh", double(success?: true)])
      
      forks_output = [
        '{"owner":"user1","name":"repo","url":"https://github.com/user1/repo","updated_at":"2024-01-01"}',
        '{"owner":"user2","name":"repo","url":"https://github.com/user2/repo","updated_at":"2024-01-02"}'
      ].join("\n")
      
      allow(Open3).to receive(:capture2e).with(/gh api repos/).and_return(
        [forks_output, double(success?: true)]
      )
    end

    it "lists forks of a repository" do
      forks = client.list_forks("original", "repo")
      
      expect(forks.size).to eq(2)
      expect(forks.first[:owner]).to eq("user1")
      expect(forks.last[:owner]).to eq("user2")
    end
  end

  describe "#list_pull_requests" do
    before do
      allow(Open3).to receive(:capture2e).with("which gh").and_return(["/usr/bin/gh", double(success?: true)])
      
      prs_json = [
        {
          number: 1,
          title: "Fix bug",
          author: { login: "user1" },
          state: "OPEN",
          createdAt: "2024-01-01"
        },
        {
          number: 2,
          title: "Add feature",
          author: { login: "user2" },
          state: "MERGED",
          createdAt: "2024-01-02"
        }
      ].to_json
      
      allow(Open3).to receive(:capture2e).with(/gh pr list/).and_return(
        [prs_json, double(success?: true)]
      )
    end

    it "lists pull requests" do
      prs = client.list_pull_requests("owner", "repo")
      
      expect(prs.size).to eq(2)
      expect(prs.first[:number]).to eq(1)
      expect(prs.first[:title]).to eq("Fix bug")
      expect(prs.first[:author]).to eq("user1")
    end
  end
end
