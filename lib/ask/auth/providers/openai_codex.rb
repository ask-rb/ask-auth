# frozen_string_literal: true

require "json"
require "base64"
require_relative "oauth"

module Ask
  module Auth
    module Providers
      # OpenAI Codex OAuth — "bring your ChatGPT subscription" (Plus/Pro).
      #
      # Users authenticate with their OpenAI account (PKCE against
      # auth.openai.com, the public Codex client id) and get tokens that
      # route requests through their subscription quota instead of the
      # pay-per-token API — flat-rate, like Cline/Hermes/opencode.
      #
      #   provider = Ask::Auth::Providers::OpenaiCodex.new(redirect_uri: "...")
      #   url = provider.authorize_url(user: current_user)
      #   tokens = provider.authorize!(user: current_user, code: params[:code])
      #   provider.refresh(refresh_token: tokens[:refresh_token])
      #
      # #authorize! returns { token:, refresh_token:, expires_at:, account_id:, raw: }.
      # Models are tier-filtered with .allowed_model? (mirrors opencode's
      # codex.ts: the OAuth path excludes pro-reasoning and gpt-5.6, and only
      # gpt-5.4+ general models are allowed).
      class OpenaiCodex < OAuth
        CLIENT_ID = "app_EMoamEEZ73f0CkXaXp7hrann"
        ISSUER = "https://auth.openai.com"
        AUTHORIZE_URL = "#{ISSUER}/oauth/authorize"
        TOKEN_URL = "#{ISSUER}/oauth/token"
        SCOPE = "openid profile email offline_access"

        ALLOWED_MODELS = %w[gpt-5.5 gpt-5.3-codex-spark gpt-5.4 gpt-5.4-mini].freeze
        DISALLOWED_MODELS = %w[gpt-5.5-pro].freeze

        def initialize(storage: nil, client_id: CLIENT_ID, redirect_uri: nil, http: Ask::Auth::OAuth::HTTP)
          super(
            storage: storage,
            client_id: client_id,
            authorize_url: AUTHORIZE_URL,
            token_url: TOKEN_URL,
            redirect_uri: redirect_uri,
            scope: SCOPE,
            http: http
          )
        end

        def authorize_url(user:, verifier: nil, state: nil)
          super(user: user, verifier: verifier, state: state, extra_params: {id_token_add_organizations: "true"})
        end

        def parse_token_response(body)
          data = JSON.parse(body)
          {
            token: data["access_token"],
            refresh_token: data["refresh_token"],
            expires_at: data["expires_in"] ? Time.now + data["expires_in"].to_i : nil,
            account_id: self.class.account_id_from(data["id_token"]),
            raw: data
          }
        rescue JSON::ParserError => e
          raise OAuthError, "bad token response: #{e.message}"
        end

        # Whether a model id is usable through a ChatGPT subscription's OAuth
        # path. General gpt-5.4+ models and the codex family are allowed;
        # pro-reasoning models (gpt-5.5-pro) and gpt-5.6 are not.
        def self.allowed_model?(model_id)
          return true if ALLOWED_MODELS.include?(model_id)
          return false if DISALLOWED_MODELS.include?(model_id) || model_id == "gpt-5.6"

          match = model_id.match(/\Agpt-(\d+\.\d+)/)
          match ? match[1].to_f > 5.4 : false
        end

        # The ChatGPT account id, from the id_token's JWT claims — sent as
        # the ChatGPT-Account-Id header on API calls.
        def self.account_id_from(id_token)
          claims = decode_jwt_claims(id_token)
          claims["chatgpt_account_id"] ||
            claims.dig("https://api.openai.com/auth", "chatgpt_account_id") ||
            claims.dig("organizations", 0, "id")
        end

        def self.decode_jwt_claims(token)
          payload = token.to_s.split(".")[1]
          return {} if payload.to_s.empty?

          decoded = Base64.urlsafe_decode64(payload)
          JSON.parse(decoded)
        rescue ArgumentError, JSON::ParserError
          {}
        end
      end
    end
  end
end
