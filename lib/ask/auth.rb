# frozen_string_literal: true

require_relative "auth/version"
require_relative "auth/providers/env"
require_relative "auth/providers/file"
require_relative "auth/providers/rails_credentials"
require_relative "auth/providers/database"
require_relative "auth/providers/oauth"

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
      def initialize(name)
        super("No credential found for #{name.inspect}. " \
              "Set #{name.to_s.upcase} in your environment, add it to ~/.ask/credentials.yml, " \
              "or configure a provider.")
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
      # +name+:: Symbol or String identifying the credential (e.g. +:github_token+)
      # +user+:: Optional user record for per-user providers (Database, OAuth)
      def resolve(name, user: nil)
        name = name.to_s.strip
        return nil if name.empty?

        configuration.providers.each do |provider|
          value = provider.call(name, user: user)
          next if value.nil?

          normalized = normalize(value)
          return normalized unless normalized.nil?
        end

        raise MissingCredential, name
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
