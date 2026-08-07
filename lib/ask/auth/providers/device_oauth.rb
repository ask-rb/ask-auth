# frozen_string_literal: true

require "json"
require_relative "oauth"

module Ask
  module Auth
    module Providers
      # RFC 8628 device authorization grant (OAuth 2.0 device flow) — the
      # headless-friendly alternative to authorization-code PKCE: no
      # redirect_uri, no callback route. The user opens a URL on any
      # device, types a short code, and we long-poll the token endpoint.
      #
      #   provider = Ask::Auth::Providers::Xai.new
      #   device = provider.start_device_flow(user: current_user)
      #   # render device[:verification_uri] + device[:user_code]
      #   tokens = provider.complete_device_flow(user:, device_code: device[:device_code])
      #   # raises PendingAuthorization until the user authorizes
      #
      # Subclasses set client_id, token_url, device_code_url, and scope.
      class DeviceOAuth < OAuth
        DEVICE_CODE_GRANT_TYPE = "urn:ietf:params:oauth:grant-type:device_code"

        # The user hasn't authorized yet — the caller should wait and retry.
        class PendingAuthorization < StandardError; end

        def initialize(storage: nil, client_id: nil, token_url: nil, device_code_url: nil,
          scope: nil, http: Ask::Auth::OAuth::HTTP)
          super(storage: storage, client_id: client_id, authorize_url: nil, token_url: token_url,
            redirect_uri: nil, scope: scope, http: http)
          @device_code_url = device_code_url
        end

        # Step 1: ask the provider for a device + user code.
        # Returns { device_code:, user_code:, verification_uri:, interval:, expires_at: }.
        def start_device_flow(user: nil)
          raise OAuthError, "device_code_url not configured" if @device_code_url.to_s.empty?

          status, body = @http.post_form(@device_code_url, {client_id: @client_id, scope: @scope.to_s})
          raise OAuthError, "device authorization request failed (#{status}): #{body.to_s[0, 200]}" unless status == 200

          data = JSON.parse(body)
          {
            device_code: data["device_code"],
            user_code: data["user_code"],
            verification_uri: data["verification_uri"] || data["verification_url"],
            interval: data["interval"].to_i,
            expires_at: data["expires_in"].to_i > 0 ? Time.now + data["expires_in"].to_i : nil
          }
        rescue JSON::ParserError => e
          raise OAuthError, "bad device authorization response: #{e.message}"
        end

        # Step 2: poll the token endpoint. Returns the token hash on
        # success (same shape as #authorize!), or raises PendingAuthorization
        # when the user hasn't authorized yet.
        def complete_device_flow(user: nil, device_code:)
          status, body = @http.post_form(token_url_for, {
            grant_type: DEVICE_CODE_GRANT_TYPE,
            device_code: device_code,
            client_id: @client_id
          })
          data = parse_json(body)

          case status
          when 200
            parse_token_response(body)
          when 400
            case data["error"]
            when "authorization_pending", "slow_down"
              raise PendingAuthorization
            when "access_denied", "expired_token"
              raise OAuthError, "device authorization #{data["error"]}"
            else
              raise OAuthError, "device authorization failed (#{status}): #{data["error_description"] || data["error"]}"
            end
          else
            raise OAuthError, "device authorization failed (#{status}): #{body.to_s[0, 200]}"
          end
        end

        private

        def token_url_for
          @token_url || raise(OAuthError, "token_url not configured")
        end

        def parse_json(body)
          JSON.parse(body)
        rescue JSON::ParserError
          {}
        end
      end
    end
  end
end
