# frozen_string_literal: true

require "yaml"
require "fileutils"

module Ask
  module Auth
    module Providers
      # Reads credentials from a YAML file (default: +~/.ask/credentials.yml+).
      #
      #   Ask::Auth::Providers::File.new(path: "~/.ask/credentials.yml")
      #
      # The file is automatically created (with 0600 permissions) when writing,
      # but this provider is read-only by design.
      class File
        DEFAULT_PATH = "~/.ask/credentials.yml"

        def initialize(path: DEFAULT_PATH)
          @path = path
        end

        # Returns the credential value from the YAML file, or nil.
        def call(name, user: nil)
          data = load_file
          return nil unless data

          return nil unless name.is_a?(String) || name.is_a?(Symbol)
          value = data[name.to_s] || data[name.to_sym]
          value
        end

        # The path this provider reads from.
        attr_reader :path

        private

        def load_file
          expanded = ::File.expand_path(@path)
          return nil unless ::File.exist?(expanded)

          YAML.safe_load(::File.read(expanded), permitted_classes: [Symbol]) || {}
        rescue Psych::SyntaxError
          nil
        end
      end
    end
  end
end
