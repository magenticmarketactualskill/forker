# frozen_string_literal: true

require "forker"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Clean up test directories after each test
  config.after(:each) do
    test_forker_dir = File.join(Dir.pwd, ".forker_test")
    FileUtils.rm_rf(test_forker_dir) if Dir.exist?(test_forker_dir)
  end
end
