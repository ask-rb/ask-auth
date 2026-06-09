# frozen_string_literal: true

module Ask
  module Auth
    module Providers
      # Resolves credentials from Rails encrypted credentials.
      #
      # Convention: +resolve(:github_token)+ looks up +Rails.application.credentials.github.token+
      # (dot-separated path from the credential name).
      #
      # Safely returns nil when Rails is not loaded.
      class RailsCredentials
        def call(name, user: nil)
          return nil unless defined?(::Rails) && ::Rails.application.respond_to?(:credentials)

          parts = name.to_s.split("_")
          value = parts.reduce(::Rails.application.credentials) do |obj, part|
            break nil unless obj.respond_to?(part)
            obj.public_send(part)
          end

          value
        end
      end
    end
  end
end
