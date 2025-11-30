# frozen_string_literal: true

require_relative "lib/forker/version"

Gem::Specification.new do |spec|
  spec.name = "forker"
  spec.version = Forker::VERSION
  spec.authors = ["Forker Team"]
  spec.email = ["team@forker.dev"]

  spec.summary = "Fork management tool for Ruby gems"
  spec.description = "Manage forked gems using git and GitHub CLI. Track fork relationships, monitor activity, and discover collaborators in the fork ecosystem."
  spec.homepage = "https://github.com/magenticmarketactualskill/forker"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.glob(%w[
    lib/**/*.rb
    bin/*
    README.md
    LICENSE.txt
    CHANGELOG.md
  ])
  spec.bindir = "bin"
  spec.executables = ["forker"]
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "thor", "~> 1.3"

  # Development dependencies
  spec.add_development_dependency "rspec", "~> 3.13"
  spec.add_development_dependency "cucumber", "~> 9.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rubocop", "~> 1.21"
end
