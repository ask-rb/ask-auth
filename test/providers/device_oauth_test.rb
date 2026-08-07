# frozen_string_literal: true

require_relative "../test_helper"

class DeviceOAuthProviderTest < Minitest::Test
  def setup
    @provider = Ask::Auth::Providers::Xai.new
  end

  def test_start_device_flow_requests_a_device_code
    http = stub("http")
    http.stubs(:post_form).with(
      "https://auth.x.ai/oauth2/device/code",
      {client_id: Ask::Auth::Providers::Xai::CLIENT_ID, scope: Ask::Auth::Providers::Xai::SCOPE}
    ).returns([200, JSON.generate(
      device_code: "dc-1", user_code: "ABCD-EFGH",
      verification_uri: "https://auth.x.ai/activate", interval: 5, expires_in: 300
    )])
    provider = Ask::Auth::Providers::Xai.new(http: http)

    device = provider.start_device_flow(user: stub("user", id: 1))

    assert_equal "dc-1", device[:device_code]
    assert_equal "ABCD-EFGH", device[:user_code]
    assert_equal "https://auth.x.ai/activate", device[:verification_uri]
    assert_equal 5, device[:interval]
    assert device[:expires_at] > Time.now
  end

  def test_complete_device_flow_returns_tokens
    http = stub("http")
    http.stubs(:post_form).with(
      "https://auth.x.ai/oauth2/token",
      {grant_type: "urn:ietf:params:oauth:grant-type:device_code", device_code: "dc-1", client_id: Ask::Auth::Providers::Xai::CLIENT_ID}
    ).returns([200, JSON.generate(access_token: "acc", refresh_token: "ref", expires_in: 3600)])
    provider = Ask::Auth::Providers::Xai.new(http: http)

    tokens = provider.complete_device_flow(user: stub("user", id: 1), device_code: "dc-1")

    assert_equal "acc", tokens[:token]
    assert_equal "ref", tokens[:refresh_token]
  end

  def test_complete_device_flow_raises_pending_until_authorized
    http = stub("http")
    http.stubs(:post_form).returns([400, JSON.generate(error: "authorization_pending")])
    provider = Ask::Auth::Providers::Xai.new(http: http)

    assert_raises(Ask::Auth::Providers::DeviceOAuth::PendingAuthorization) do
      provider.complete_device_flow(user: stub("user", id: 1), device_code: "dc-1")
    end
  end

  def test_complete_device_flow_raises_on_denial
    http = stub("http")
    http.stubs(:post_form).returns([400, JSON.generate(error: "access_denied")])
    provider = Ask::Auth::Providers::Xai.new(http: http)

    assert_raises(Ask::Auth::OAuthError) do
      provider.complete_device_flow(user: stub("user", id: 1), device_code: "dc-1")
    end
  end

  def test_xai_constants
    assert_equal "b1a00492-073a-47ea-816f-4c329264a828", Ask::Auth::Providers::Xai::CLIENT_ID
  end

  def test_github_copilot_constants_and_scope
    assert_equal "Ov23li8tweQw6odWQebz", Ask::Auth::Providers::GithubCopilot::CLIENT_ID
    assert_equal "https://github.com/login/device/code", Ask::Auth::Providers::GithubCopilot::DEVICE_CODE_URL
    assert_equal "read:user", Ask::Auth::Providers::GithubCopilot::SCOPE
  end

  def test_github_copilot_start_flow_uses_its_urls
    http = stub("http")
    http.stubs(:post_form).with(
      "https://github.com/login/device/code",
      {client_id: "Ov23li8tweQw6odWQebz", scope: "read:user"}
    ).returns([200, JSON.generate(device_code: "dc-1", user_code: "ABCD", verification_uri: "https://github.com/login/device", interval: 5)])
    provider = Ask::Auth::Providers::GithubCopilot.new(http: http)

    device = provider.start_device_flow

    assert_equal "https://github.com/login/device", device[:verification_uri]
  end
end
