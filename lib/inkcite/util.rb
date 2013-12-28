# Symbolize keys!
require 'active_support/core_ext/hash/keys.rb'
require 'yaml'

module Inkcite
  module Util

    def self.each_line path, fail_if_not_exists, &block

      if File.exists?(path)
        File.open(path, 'r:windows-1252:utf-8').each { |line| yield line.strip }
      elsif fail_if_not_exists
        raise "File not found: #{path}"
      end

    end

    def self.read *argv
      path = File.join(File.expand_path('../..', File.dirname(__FILE__)), argv)
      if File.exists?(path)
        line = File.open(path).read
        line.gsub!(/[\r\f\n]+/, "\n")
        line.gsub!(/ {2,}/, ' ')
        line
      end
    end

    def self.read_yml file, fail_if_not_exists=false
      if File.exist?(file)
        symbolize_keys(YAML.load_file(file))
      elsif fail_if_not_exists
        raise "File not found: #{file}" if fail_if_not_exists
      else
        {}
      end
    end

    private

    # Recursive key symbolization for the provided Hash.
    def self.symbolize_keys hash
      unless hash.nil?
        hash.symbolize_keys!
        hash.each do |k, v|
          symbolize_keys(v) if v.is_a?(Hash)
        end
      end
      hash
    end

  end
end
