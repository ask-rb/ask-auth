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

  def test_authorize_raises_not_implemented
    assert_raises(NotImplementedError) do
      @provider.authorize!(user: stub("user", id: 1), code: "auth-code")
    end
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
