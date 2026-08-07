# frozen_string_literal: true

require_relative "device_oauth"

module Ask
  module Auth
    module Providers
      # GitHub Copilot device OAuth — "bring your Copilot subscription".
      # RFC 8628 device grant against github.com/login/device/code (the
      # public Copilot CLI client id). Constants mirror opencode's
      # github-copilot/copilot.ts.
      #
      # Note: Copilot's device flow is a gray area of GitHub's terms — it
      # works, but treat it as a user-beware integration.
      class GithubCopilot < DeviceOAuth
        CLIENT_ID = "Ov23li8tweQw6odWQebz"
        DEVICE_CODE_URL = "https://github.com/login/device/code"
        ACCESS_TOKEN_URL = "https://github.com/login/oauth/access_token"
        SCOPE = "read:user"

        def initialize(storage: nil, client_id: CLIENT_ID, http: Ask::Auth::OAuth::HTTP)
          super(storage: storage, client_id: client_id, token_url: ACCESS_TOKEN_URL,
            device_code_url: DEVICE_CODE_URL, scope: SCOPE, http: http)
        end
      end
    end
  end
end
