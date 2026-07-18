# frozen_string_literal: true

module Ask
  module Auth
    module Providers
      # Resolves credentials from Rails encrypted credentials.
      #
      # Supports two lookup modes determined by the +name+ argument type:
      #
      #   Symbol/String  → flat key, looked up literally
      #     resolve(:opencode_api_key)      → credentials.opencode_api_key
      #     resolve("opencode_api_key")     → credentials.opencode_api_key
      #
      #   Array          → path segments, navigated in order
      #     resolve([:opencode, :api_key])  → credentials.opencode.api_key
      #     resolve([:opencode, :go, :api_key]) → credentials.opencode.go.api_key
      #
      # No splitting, no guessing. The caller determines the lookup path.
      #
      # Safely returns nil when Rails is not loaded.
      class RailsCredentials
        def call(name, user: nil)
          return nil unless defined?(::Rails) && ::Rails.application.respond_to?(:credentials)

          creds = ::Rails.application.credentials
          parts = Array(name).map { |p| p.to_s.strip }
          return nil if parts.empty? || parts.any?(&:empty?)

          # Navigate the path segments. Must check the VALUE, not just
          # respond_to?, because ActiveSupport::OrderedOptions#respond_to?
          # returns true for any method name, even when the key doesn't exist.
          value = parts.reduce(creds) do |obj, part|
            begin
              val = obj.public_send(part)
              break nil if val.nil?
              val
            rescue NoMethodError
              break nil
            end
          end

          value
        end
      end
    end
  end
end
