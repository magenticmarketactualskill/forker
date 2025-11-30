# frozen_string_literal: true

Given("a clean forker environment") do
  @storage = Forker::Storage.new(Dir.pwd)
  @fork_data = {}
  @peers_data = {}
  @prs_data = {}
end

When("I initialize forker storage") do
  @forker_path = @storage.ensure_forker_directory
end

Then("the .forker directory should exist") do
  expect(Dir.exist?(@forker_path)).to be true
end

Then("the .forker directory should be empty") do
  entries = Dir.entries(@forker_path).reject { |e| e.start_with?(".") }
  expect(entries).to be_empty
end

Given("I have fork information for {string}") do |gem_name|
  @fork_data[gem_name] = {
    name: gem_name,
    url: "https://github.com/user/#{gem_name}",
    root_url: "https://github.com/original/#{gem_name}",
    updated_at: Time.now.to_s
  }
end

When("I save the fork information") do
  @fork_data.each do |gem_name, data|
    @storage.save_fork_info(gem_name, data)
  end
end

When("I save all fork information") do
  @fork_data.each do |gem_name, data|
    @storage.save_fork_info(gem_name, data)
  end
end

Then("the fork information should be stored in .forker\\/test_gem\\/fork_info.json") do
  file_path = File.join(@storage.gem_directory("test_gem"), "fork_info.json")
  expect(File.exist?(file_path)).to be true
end

Then("I should be able to load the fork information") do
  loaded = @storage.load_fork_info("test_gem")
  expect(loaded).not_to be_nil
  expect(loaded[:name]).to eq("test_gem")
end

Then("I should have {int} tracked gems") do |count|
  tracked = @storage.list_tracked_gems
  expect(tracked.size).to eq(count)
end

Then("the tracked gems should include {string} and {string}") do |gem1, gem2|
  tracked = @storage.list_tracked_gems
  expect(tracked).to include(gem1, gem2)
end

Given("I have peers information for {string}") do |gem_name|
  @peers_data[gem_name] = [
    { owner: "user1", name: gem_name, url: "https://github.com/user1/#{gem_name}" },
    { owner: "user2", name: gem_name, url: "https://github.com/user2/#{gem_name}" }
  ]
end

When("I save the peers information") do
  @peers_data.each do |gem_name, peers|
    @storage.save_peers(gem_name, peers)
  end
end

Then("the peers information should be stored") do
  file_path = File.join(@storage.gem_directory("test_gem"), "peers.json")
  expect(File.exist?(file_path)).to be true
end

Then("I should be able to load the peers information") do
  loaded = @storage.load_peers("test_gem")
  expect(loaded).not_to be_empty
  expect(loaded.size).to eq(2)
end

Given("I have pull requests information for {string}") do |gem_name|
  @prs_data[gem_name] = [
    { number: 1, title: "Fix bug", author: "user1", state: "open" },
    { number: 2, title: "Add feature", author: "user2", state: "merged" }
  ]
end

When("I save the pull requests information") do
  @prs_data.each do |gem_name, prs|
    @storage.save_prs(gem_name, prs)
  end
end

Then("the pull requests should be stored") do
  file_path = File.join(@storage.gem_directory("test_gem"), "prs.json")
  expect(File.exist?(file_path)).to be true
end

Then("I should be able to load the pull requests") do
  loaded = @storage.load_prs("test_gem")
  expect(loaded).not_to be_empty
  expect(loaded.size).to eq(2)
end

Given("I have saved the fork information") do
  @storage.save_fork_info("test_gem", @fork_data["test_gem"])
end

When("I delete the fork data") do
  @storage.delete_gem_data("test_gem")
end

Then("the fork directory should not exist") do
  gem_dir = File.join(@storage.instance_variable_get(:@forker_path), "test_gem")
  expect(Dir.exist?(gem_dir)).to be false
end
