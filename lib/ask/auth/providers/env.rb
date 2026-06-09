# frozen_string_literal: true

module Ask
  module Auth
    module Providers
      # Resolves credentials from environment variables.
      #
      # Conventions tested (in order):
      #   resolve(:github_token)  ->  ENV["GITHUB_TOKEN"], ENV["GITHUBTOKEN"], ENV["github_token"]
      #
      # No configuration needed — just a convention.
      class Env
        # Returns the credential value from ENV, or nil if not found.
        def call(name, user: nil)
          conventions(name).each do |key|
            value = ENV[key.to_s]
            return value unless value.nil?
          end
          nil
        end

        private

        def conventions(name)
          name = name.to_s
          [
            name.upcase,
            name.upcase.delete("_"),
            name
          ].uniq
        end
      end
    end
  end
end
