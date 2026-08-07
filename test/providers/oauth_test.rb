# frozen_string_literal: true

require_relative "../test_helper"

class OAuthProviderTest < Minitest::Test
  def setup
    @provider = Ask::Auth::Providers::OAuth.new
  end

  def test_call_returns_nil_by_default
    assert_nil @provider.call(:github_token)
  end

  def test_generate_code_verifier_returns_128_char_string
    verifier = @provider.generate_code_verifier
    assert_equal 128, verifier.length
    assert verifier.match?(/\A[A-Za-z0-9]+\z/)
  end

  def test_generate_code_challenge_returns_base64_string
    verifier = @provider.generate_code_verifier
    challenge = @provider.generate_code_challenge(verifier)

    refute_nil challenge
    refute challenge.include?("=")
    assert challenge.match?(/\A[A-Za-z0-9\-_]+\z/)
  end

  def test_authorize_url_returns_uri_string
    url = @provider.authorize_url(user: stub("user", id: 1))
    assert url.start_with?("https://")
    assert_includes url, "code_challenge="
    assert_includes url, "code_challenge_method=S256"
    assert_includes url, "state="
  end

  def test_authorize_requires_a_token_url
    assert_raises(Ask::Auth::OAuthError) do
      @provider.authorize!(user: stub("user", id: 1), code: "auth-code", code_verifier: "verifier")
    end
  end

  def test_authorize_exchanges_the_code_for_tokens
    http = stub("http")
    http.stubs(:post_form).with(
      "https://issuer.example/token",
      {grant_type: "authorization_code", code: "auth-code",
       redirect_uri: "https://app.example/callback", client_id: "my-client",
       code_verifier: "verifier"}
    ).returns([200, %({"access_token":"acc","refresh_token":"ref","expires_in":3600})])

    provider = Ask::Auth::Providers::OAuth.new(
      client_id: "my-client",
      token_url: "https://issuer.example/token",
      redirect_uri: "https://app.example/callback",
      http: http
    )

    tokens = provider.authorize!(user: stub("user", id: 1), code: "auth-code", code_verifier: "verifier")

    assert_equal "acc", tokens[:token]
    assert_equal "ref", tokens[:refresh_token]
    assert tokens[:expires_at] > Time.now
  end

  def test_authorize_raises_on_non_200
    http = stub("http")
    http.stubs(:post_form).returns([400, "bad request"])

    provider = Ask::Auth::Providers::OAuth.new(token_url: "https://issuer.example/token", http: http)

    assert_raises(Ask::Auth::OAuthError) do
      provider.authorize!(user: stub("user", id: 1), code: "auth-code", code_verifier: "verifier")
    end
  end

  def test_refresh_uses_refresh_token_grant
    http = stub("http")
    http.stubs(:post_form).with(
      "https://issuer.example/token",
      {grant_type: "refresh_token", refresh_token: "ref", client_id: "my-client"}
    ).returns([200, %({"access_token":"acc2","refresh_token":"ref2","expires_in":3600})])

    provider = Ask::Auth::Providers::OAuth.new(
      client_id: "my-client",
      token_url: "https://issuer.example/token",
      http: http
    )

    tokens = provider.refresh(refresh_token: "ref")

    assert_equal "acc2", tokens[:token]
    assert_equal "ref2", tokens[:refresh_token]
  end

  def test_authorize_recovers_the_verifier_from_storage
    user = stub("user", id: 1)
    storage = stub("storage")
    storage.stubs(:fetch).with(:oauth_state, user: user).returns({verifier: "stored-verifier", state: "st"})

    http = stub("http")
    http.stubs(:post_form).returns([200, %({"access_token":"acc","expires_in":3600})])

    provider = Ask::Auth::Providers::OAuth.new(
      client_id: "my-client",
      token_url: "https://issuer.example/token",
      storage: storage,
      http: http
    )

    tokens = provider.authorize!(user: user, code: "auth-code")

    assert_equal "acc", tokens[:token]
  end

  def test_authorize_url_persists_verifier_and_state
    stored = nil
    storage = Object.new
    storage.define_singleton_method(:store) { |name, user:, value:| stored = value }
    user = stub("user", id: 1)

    provider = Ask::Auth::Providers::OAuth.new(
      client_id: "my-client",
      authorize_url: "https://issuer.example/authorize",
      redirect_uri: "https://app.example/callback",
      scope: "openid email",
      storage: storage
    )

    url = provider.authorize_url(user: user)

    assert_includes url, "client_id=my-client"
    assert_includes url, "scope=openid+email"
    assert_includes url, "redirect_uri=https%3A%2F%2Fapp.example%2Fcallback"
    refute_nil stored
    assert stored[:verifier].length == 128
  end

  def test_authorize_url_with_custom_params
    provider = Ask::Auth::Providers::OAuth.new(
      client_id: "my-client",
      authorize_url: "https://github.com/login/oauth/authorize"
    )

    url = provider.authorize_url(user: stub("user", id: 1))
    assert_includes url, "client_id=my-client"
    assert url.start_with?("https://github.com/login/oauth/authorize")
  end
end
