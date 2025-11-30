# frozen_string_literal: true

require_relative "forker/version"
require_relative "forker/cli"
require_relative "forker/storage"
require_relative "forker/github_client"
require_relative "forker/fork_manager"

module Forker
  class Error < StandardError; end
  class GitHubError < Error; end
  class StorageError < Error; end
end
