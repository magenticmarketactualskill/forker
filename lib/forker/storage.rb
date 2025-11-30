# frozen_string_literal: true

require "fileutils"
require "json"

module Forker
  class Storage
    FORKER_DIR = ".forker"

    def initialize(base_path = Dir.pwd)
      @base_path = base_path
      @forker_path = File.join(@base_path, FORKER_DIR)
    end

    def ensure_forker_directory
      FileUtils.mkdir_p(@forker_path) unless Dir.exist?(@forker_path)
      @forker_path
    end

    def gem_directory(gem_name)
      ensure_forker_directory
      dir = File.join(@forker_path, sanitize_name(gem_name))
      FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
      dir
    end

    def save_fork_info(gem_name, data)
      dir = gem_directory(gem_name)
      file_path = File.join(dir, "fork_info.json")
      File.write(file_path, JSON.pretty_generate(data))
    end

    def load_fork_info(gem_name)
      file_path = File.join(gem_directory(gem_name), "fork_info.json")
      return nil unless File.exist?(file_path)

      JSON.parse(File.read(file_path), symbolize_names: true)
    end

    def save_peers(gem_name, peers)
      dir = gem_directory(gem_name)
      file_path = File.join(dir, "peers.json")
      File.write(file_path, JSON.pretty_generate(peers))
    end

    def load_peers(gem_name)
      file_path = File.join(gem_directory(gem_name), "peers.json")
      return [] unless File.exist?(file_path)

      JSON.parse(File.read(file_path), symbolize_names: true)
    end

    def save_prs(gem_name, prs)
      dir = gem_directory(gem_name)
      file_path = File.join(dir, "prs.json")
      File.write(file_path, JSON.pretty_generate(prs))
    end

    def load_prs(gem_name)
      file_path = File.join(gem_directory(gem_name), "prs.json")
      return [] unless File.exist?(file_path)

      JSON.parse(File.read(file_path), symbolize_names: true)
    end

    def list_tracked_gems
      ensure_forker_directory
      return [] unless Dir.exist?(@forker_path)

      Dir.entries(@forker_path)
         .reject { |entry| entry.start_with?(".") }
         .select { |entry| File.directory?(File.join(@forker_path, entry)) }
    end

    def delete_gem_data(gem_name)
      dir = gem_directory(gem_name)
      FileUtils.rm_rf(dir) if Dir.exist?(dir)
    end

    private

    def sanitize_name(name)
      # Remove special characters and convert to safe directory name
      name.gsub(/[^a-zA-Z0-9_\-]/, "_").downcase
    end
  end
end
