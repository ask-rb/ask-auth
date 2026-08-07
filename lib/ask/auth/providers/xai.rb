# frozen_string_literal: true

require_relative "device_oauth"

module Ask
  module Auth
    module Providers
      # xAI (Grok) device OAuth — "bring your xAI account": the public
      # Grok-CLI OAuth client (RFC 8628 device grant against
      # auth.x.ai/oauth2). Constants mirror opencode's xai.ts. The access
      # token works as the bearer key for the standard xAI OpenAI-compatible
      # API (api.x.ai/v1).
      class Xai < DeviceOAuth
        CLIENT_ID = "b1a00492-073a-47ea-816f-4c329264a828"
        TOKEN_URL = "https://auth.x.ai/oauth2/token"
        DEVICE_AUTHORIZATION_URL = "https://auth.x.ai/oauth2/device/code"
        SCOPE = "openid profile email offline_access grok-cli:access api:access"

        def initialize(storage: nil, client_id: CLIENT_ID, http: Ask::Auth::OAuth::HTTP)
          super(storage: storage, client_id: client_id, token_url: TOKEN_URL,
            device_code_url: DEVICE_AUTHORIZATION_URL, scope: SCOPE, http: http)
        end
      end
    end
  end
end
