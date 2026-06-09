# frozen_string_literal: true

require "base64"
require "openssl"
require "securerandom"

module Ask
  module Auth
    module Providers
      # PKCE OAuth flow for interactive credential authorization.
      #
      # This provider implements the OAuth interface. The full interactive flow
      # can be deferred — the interface is wired for integration and the PKCE
      # utility methods are ready.
      #
      #   provider = Ask::Auth::Providers::OAuth.new(storage: database_provider)
      #   url = provider.authorize_url(user: current_user)
      #   # redirect user to url, then:
      #   provider.authorize!(user: current_user, code: params[:code])
      class OAuth
        def initialize(storage: nil, client_id: nil, authorize_url: nil, token_url: nil)
          @storage = storage
          @client_id = client_id
          @authorize_url = authorize_url
          @token_url = token_url
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

        # Returns the authorization URL to redirect the user to.
        def authorize_url(user:, verifier: nil, state: nil)
          verifier ||= generate_code_verifier
          state ||= SecureRandom.hex(16)
          challenge = generate_code_challenge(verifier)

          # Store state and verifier for this user (requires a storage provider)
          if @storage && user
            @storage.call(:oauth_state, user: user)
          end

          uri = URI.parse(@authorize_url || "https://example.com/oauth/authorize")
          uri.query = URI.encode_www_form(
            response_type: "code",
            client_id: @client_id || "YOUR_CLIENT_ID",
            redirect_uri: "urn:ietf:wg:oauth:2.0:oob",
            scope: "",
            state: state,
            code_challenge: challenge,
            code_challenge_method: "S256"
          )
          uri.to_s
        end

        # Exchange an authorization code for tokens.
        # +user+:: The user to associate the credential with
        # +code+:: The authorization code from the redirect
        def authorize!(user:, code:)
          raise NotImplementedError, "Token exchange requires a configured token_url and client_id"
        end
      end
    end
  end
end
