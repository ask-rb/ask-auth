# frozen_string_literal: true

require_relative "../test_helper"

class OpenaiCodexProviderTest < Minitest::Test
  def setup
    @provider = Ask::Auth::Providers::OpenaiCodex.new(redirect_uri: "https://app.example/oauth/codex/callback")
  end

  def test_authorize_url_uses_codex_constants
    url = @provider.authorize_url(user: stub("user", id: 1))

    assert url.start_with?("https://auth.openai.com/oauth/authorize")
    assert_includes url, "client_id=#{Ask::Auth::Providers::OpenaiCodex::CLIENT_ID}"
    assert_includes url, "scope=openid+profile+email+offline_access"
    assert_includes url, "id_token_add_organizations=true"
    assert_includes url, "code_challenge_method=S256"
    assert_includes url, "redirect_uri=https%3A%2F%2Fapp.example%2Foauth%2Fcodex%2Fcallback"
  end

  def test_authorize_exchanges_code_and_extracts_account_id
    user = stub("user", id: 1)
    id_token = build_id_token("chatgpt_account_id" => "acct_123")

    http = stub("http")
    http.stubs(:post_form).returns([200, JSON.generate(
      access_token: "acc", refresh_token: "ref", expires_in: 3600, id_token: id_token
    )])

    provider = Ask::Auth::Providers::OpenaiCodex.new(redirect_uri: "https://app.example/cb", http: http)
    tokens = provider.authorize!(user: user, code: "auth-code", code_verifier: "verifier")

    assert_equal "acc", tokens[:token]
    assert_equal "ref", tokens[:refresh_token]
    assert_equal "acct_123", tokens[:account_id]
    assert tokens[:expires_at] > Time.now
  end

  def test_refresh_grant
    http = stub("http")
    http.stubs(:post_form).returns([200, JSON.generate(access_token: "acc2", refresh_token: "ref2", expires_in: 3600)])

    provider = Ask::Auth::Providers::OpenaiCodex.new(http: http)
    tokens = provider.refresh(refresh_token: "ref")

    assert_equal "acc2", tokens[:token]
    assert_equal "ref2", tokens[:refresh_token]
  end

  def test_allowed_models
    assert Ask::Auth::Providers::OpenaiCodex.allowed_model?("gpt-5.5")
    assert Ask::Auth::Providers::OpenaiCodex.allowed_model?("gpt-5.4")
    assert Ask::Auth::Providers::OpenaiCodex.allowed_model?("gpt-5.3-codex-spark")
    assert Ask::Auth::Providers::OpenaiCodex.allowed_model?("gpt-5.9")

    refute Ask::Auth::Providers::OpenaiCodex.allowed_model?("gpt-5.5-pro")
    refute Ask::Auth::Providers::OpenaiCodex.allowed_model?("gpt-5.6")
    refute Ask::Auth::Providers::OpenaiCodex.allowed_model?("gpt-5.3")
    refute Ask::Auth::Providers::OpenaiCodex.allowed_model?("claude-sonnet-4")
  end

  def test_account_id_from_id_token
    assert_equal "acct_123", Ask::Auth::Providers::OpenaiCodex.account_id_from(
      build_id_token("chatgpt_account_id" => "acct_123")
    )
    assert_equal "acct_456", Ask::Auth::Providers::OpenaiCodex.account_id_from(
      build_id_token("https://api.openai.com/auth" => {"chatgpt_account_id" => "acct_456"})
    )
    assert_equal "org_7", Ask::Auth::Providers::OpenaiCodex.account_id_from(
      build_id_token("organizations" => [{"id" => "org_7"}])
    )
    assert_nil Ask::Auth::Providers::OpenaiCodex.account_id_from("not-a-jwt")
    assert_nil Ask::Auth::Providers::OpenaiCodex.account_id_from(nil)
  end

  private

  def build_id_token(claims)
    header = Base64.urlsafe_encode64(JSON.generate({alg: "none"}), padding: false)
    payload = Base64.urlsafe_encode64(JSON.generate(claims), padding: false)
    "#{header}.#{payload}."
  end
end
