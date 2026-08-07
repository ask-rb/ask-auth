# frozen_string_literal: true

require "base64"
require "json"
require "openssl"
require "securerandom"
require_relative "../oauth/http"

module Ask
  module Auth
    module Providers
      # Authorization-code PKCE OAuth flow for interactive credential
      # authorization (e.g. bring-your-own-subscription).
      #
      #   provider = Ask::Auth::Providers::OAuth.new(
      #     client_id: "...", authorize_url: "...", token_url: "...",
      #     redirect_uri: "https://app.example/oauth/callback", scope: "..."
      #   )
      #   url = provider.authorize_url(user: current_user)
      #   # redirect user to url; the callback receives ?code=...&state=...
      #   tokens = provider.authorize!(user: current_user, code: params[:code])
      #   # { token:, refresh_token:, expires_at:, raw: {...} }
      #
      # The code verifier is generated during #authorize_url. Persist it via
      # a storage object that responds to #store(name, user:, value:) /
      # #fetch(name, user:) — the app implements it (e.g. on its OAuth state
      # table) — or pass code_verifier: back into #authorize! yourself.
      #
      # Subclasses override #parse_token_response to add provider-specific
      # fields (e.g. an account id from the id_token).
      class OAuth
        attr_reader :client_id, :redirect_uri

        def initialize(storage: nil, client_id: nil, authorize_url: nil, token_url: nil,
          redirect_uri: nil, scope: nil, http: Ask::Auth::OAuth::HTTP)
          @storage = storage
          @client_id = client_id
          @authorize_url = authorize_url
          @token_url = token_url
          @redirect_uri = redirect_uri
          @scope = scope
          @http = http
        end

        # Returns nil (no automatic resolution) — OAuth requires interactive flow.
        def call(name, user: nil)
          nil
        end

        # Generate a PKCE code verifier (128-char alphanumeric string).
        def generate_code_verifier
          SecureRandom.alphanumeric(128)
        end

        # Generate a PKCE code challenge (SHA256 base64 digest of verifier).
        def generate_code_challenge(verifier)
          ::Base64.urlsafe_encode64(
            OpenSSL::Digest.digest("SHA256", verifier),
            padding: false
          )
        end

        # Returns the authorization URL to redirect the user to. The code
        # verifier (and state) are persisted via the storage object when one
        # is configured, so the callback can recover them.
        def authorize_url(user:, verifier: nil, state: nil, extra_params: {})
          verifier ||= generate_code_verifier
          state ||= SecureRandom.hex(16)
          challenge = generate_code_challenge(verifier)

          persist_oauth_state(user, verifier, state)

          params = {
            response_type: "code",
            client_id: @client_id,
            redirect_uri: redirect_uri_value,
            scope: @scope.to_s,
            state: state,
            code_challenge: challenge,
            code_challenge_method: "S256"
          }.merge(extra_params)

          uri = URI.parse(@authorize_url || "https://example.com/oauth/authorize")
          uri.query = URI.encode_www_form(params)
          uri.to_s
        end

        # Exchange an authorization code for tokens.
        #
        # Returns { token:, refresh_token:, expires_at:, raw: {...} } (plus
        # any subclass-added keys). Raises OAuthError on transport or
        # provider errors.
        def authorize!(user:, code:, code_verifier: nil, redirect_uri: nil)
          verifier = code_verifier || fetch_oauth_state(user, :verifier)
          if verifier.to_s.empty?
            raise OAuthError, "missing code verifier — pass code_verifier or persist it via a storage object"
          end

          body = token_exchange(
            grant_type: "authorization_code",
            code: code,
            redirect_uri: redirect_uri || redirect_uri_value,
            client_id: @client_id,
            code_verifier: verifier
          )
          parse_token_response(body)
        end

        # Refresh an access token using a refresh token grant.
        def refresh(refresh_token:)
          body = token_exchange(
            grant_type: "refresh_token",
            refresh_token: refresh_token,
            client_id: @client_id
          )
          parse_token_response(body)
        end

        private

        def token_exchange(**params)
          raise OAuthError, "token_url not configured" if @token_url.to_s.empty?

          status, body = @http.post_form(@token_url, params)
          raise OAuthError, "token exchange failed (#{status}): #{body.to_s[0, 200]}" unless status == 200

          body
        end

        def parse_token_response(body)
          data = JSON.parse(body)
          {
            token: data["access_token"],
            refresh_token: data["refresh_token"],
            expires_at: data["expires_in"] ? Time.now + data["expires_in"].to_i : nil,
            raw: data
          }
        rescue JSON::ParserError => e
          raise OAuthError, "bad token response: #{e.message}"
        end

        def redirect_uri_value
          @redirect_uri || "urn:ietf:wg:oauth:2.0:oob"
        end

        def persist_oauth_state(user, verifier, state)
          return unless @storage.respond_to?(:store) && user

          @storage.store(:oauth_state, user: user, value: {verifier: verifier, state: state})
        end

        def fetch_oauth_state(user, key)
          return nil unless @storage.respond_to?(:fetch) && user

          value = @storage.fetch(:oauth_state, user: user)
          value.is_a?(Hash) ? value[key] : nil
        end
      end
    end
  end
end
