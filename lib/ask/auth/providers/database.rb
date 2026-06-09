# frozen_string_literal: true

module Ask
  module Auth
    module Providers
      # ActiveRecord-backed token storage per user.
      #
      # Expects a model with +user_id+, +name+, +token+, +expires_at+, +refresh_token+.
      # Handles expiry: if the token has expired and a refresh token is available,
      # calls +refresh!+ using the stored refresh token.
      #
      # Only used when a model is configured or available. Safely returns nil otherwise.
      class Database
        # The model class used for credential storage.
        attr_reader :model

        def initialize(model: default_model)
          @model = model
        end

        def call(name, user: nil)
          return nil unless @model
          return nil unless user.respond_to?(:id)

          record = @model.respond_to?(:find_by) ? @model.find_by(user_id: user.id, name: name.to_s) : nil
          return nil unless record

          if record.respond_to?(:expired?) && record.expired?
            return nil unless record.respond_to?(:refresh!)

            record.refresh!
            record.reload if record.respond_to?(:reload)
          end

          record.respond_to?(:token) ? record.token : record
        end

        private

        def default_model
          defined?(::ActiveRecord) && defined?(::Credential) ? ::Credential : nil
        end
      end
    end
  end
end
