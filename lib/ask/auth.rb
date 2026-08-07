# frozen_string_literal: true

require_relative "auth/version"
require_relative "auth/providers/env"
require_relative "auth/providers/file"
require_relative "auth/providers/rails_credentials"
require_relative "auth/providers/database"
require_relative "auth/providers/oauth"
require_relative "auth/providers/openai_codex"
require_relative "auth/providers/device_oauth"
require_relative "auth/providers/xai"
require_relative "auth/providers/github_copilot"

module Ask
  # Credential resolution for the ask-rb ecosystem.
  #
  # Resolves credentials by walking a configured chain of providers (Env → File →
  # RailsCredentials → Database → OAuth) and returning the first match.
  #
  #   Ask::Auth.resolve(:github_token)
  #   Ask::Auth.resolve(:openai_api_key, user: current_user)
  #
  module Auth
    class MissingCredential < KeyError
      def initialize(names)
        names = Array(names).flatten
        inspected = names.map(&:inspect).join(", ")
        super("No credential found for #{inspected}. " \
              "Set one of #{names.map { |n| n.to_s.upcase }.uniq.join(", ")} in your environment, " \
              "add it to ~/.ask/credentials.yml, or configure a provider.")
      end
    end

    class OAuthError < StandardError
      def initialize(message)
        super("OAuth flow failed: #{message}")
      end
    end

    class InvalidCredential < RuntimeError
      def initialize(name, reason = "invalid or expired")
        super("Credential #{name.inspect} is #{reason}. " \
              "Please update your token and try again.")
      end
    end

    class << self
      def configure
        config = Configuration.new
        yield config
        @configuration = config
        @configuration.freeze
      end

      def configuration
        @configuration ||= default_configuration
      end

      def reset_configuration!
        @configuration = nil
      end

      # Walk providers in order and return the first non-nil credential.
      # Tries each name in order and returns the first match.
      #
      # Each +name+ can be:
      #   Symbol/String  → flat key, tried literally by all providers
      #   Array          → path segments, used for nested lookups (e.g., Rails credentials)
      #
      #   Ask::Auth.resolve(:openai_api_key)                    # flat key
      #   Ask::Auth.resolve(:opencode_api_key, :opencode_go_api_key)  # fallbacks
      #   Ask::Auth.resolve([:opencode, :api_key])              # nested path: credentials.opencode.api_key
      #   Ask::Auth.resolve(:opencode_go_api_key, [:opencode, :api_key], user: current_user)
      #
      # +names+:: One or more Symbols, Strings, or Arrays identifying the credential
      # +user+:: Optional user record for per-user providers (Database, OAuth)
      def resolve(*names, user: nil)
        return nil if names.empty?

        names.each do |name|
          # Validate the name
          parts = Array(name).map { |p| p.to_s.strip }
          next if parts.empty? || parts.any?(&:empty?)

          configuration.providers.each do |provider|
            # Pass the original form (Symbol/Array) so providers can interpret it
            value = provider.call(name, user: user)
            next if value.nil?

            normalized = normalize(value)
            return normalized unless normalized.nil?
          end
        end

        raise MissingCredential, names
      end

      private

      def default_configuration
        Configuration.new(
          providers: [
            Providers::Env.new,
            Providers::File.new,
            Providers::RailsCredentials.new,
            Providers::Database.new,
            Providers::OAuth.new
          ]
        )
      end

      # Blank normalization: empty strings and whitespace-only normalize to nil
      def normalize(value)
        value = value.to_s.strip
        value.empty? ? nil : value
      end
    end

    # Holds configuration for the resolution chain.
    class Configuration
      attr_accessor :providers

      def initialize(providers: [])
        @providers = providers
      end
    end
  end
end
