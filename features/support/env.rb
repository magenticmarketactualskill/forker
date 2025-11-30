# frozen_string_literal: true

require "forker"
require "fileutils"
require "tmpdir"

# Set up test environment
Before do
  @test_dir = Dir.mktmpdir
  @original_dir = Dir.pwd
  Dir.chdir(@test_dir)
end

After do
  Dir.chdir(@original_dir)
  FileUtils.rm_rf(@test_dir) if @test_dir && Dir.exist?(@test_dir)
end
