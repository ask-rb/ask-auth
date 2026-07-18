# frozen_string_literal: true

require_relative "test_helper"

class AuthTest < Minitest::Test
  def setup
    Ask::Auth.reset_configuration!
  end

  def teardown
    Ask::Auth.reset_configuration!
  end

  # ── resolve chain ──

  def test_resolve_returns_first_non_nil_from_providers
    provider_a = stub("a", call: nil)
    provider_b = stub("b", call: "secret")
    provider_c = stub("c", call: "never-reached")

    Ask::Auth.configure do |c|
      c.providers = [provider_a, provider_b, provider_c]
    end

    assert_equal "secret", Ask::Auth.resolve(:test_key)
  end

  def test_resolve_walks_entire_chain_when_all_return_nil
    provider_a = stub("a", call: nil)
    provider_b = stub("b", call: nil)

    Ask::Auth.configure do |c|
      c.providers = [provider_a, provider_b]
    end

    assert_raises(Ask::Auth::MissingCredential) { Ask::Auth.resolve(:unknown) }
  end

  def test_resolve_passes_name_and_user_to_providers
    user = Object.new
    provider = stub("p")

    provider.expects(:call).with(:github_token, user: user).returns("token")

    Ask::Auth.configure do |c|
      c.providers = [provider]
    end

    assert_equal "token", Ask::Auth.resolve(:github_token, user: user)
  end

  def test_resolve_normalizes_string_names
    provider = stub("p", call: "val")
    Ask::Auth.configure { |c| c.providers = [provider] }

    assert_equal "val", Ask::Auth.resolve("TEST_KEY")
  end

  # ── blank normalization ──

  def test_empty_string_normalizes_to_nil
    provider = stub("p", call: "")
    Ask::Auth.configure { |c| c.providers = [provider] }

    assert_raises(Ask::Auth::MissingCredential) { Ask::Auth.resolve(:empty) }
  end

  def test_whitespace_string_normalizes_to_nil
    provider = stub("p", call: "   ")
    Ask::Auth.configure { |c| c.providers = [provider] }

    assert_raises(Ask::Auth::MissingCredential) { Ask::Auth.resolve(:spaces) }
  end

  def test_blank_normalization_skips_to_next_provider
    blank = stub("blank", call: "")
    actual = stub("actual", call: "real-token")

    Ask::Auth.configure do |c|
      c.providers = [blank, actual]
    end

    assert_equal "real-token", Ask::Auth.resolve(:key)
  end

  # ── configure ──

  def test_configure_accepts_block
    provider = stub("p", call: "v")
    Ask::Auth.configure do |c|
      c.providers = [provider]
    end

    assert_equal "v", Ask::Auth.resolve(:test)
  end

  def test_configure_with_no_providers_raises_missing
    Ask::Auth.configure { |c| c.providers = [] }

    assert_raises(Ask::Auth::MissingCredential) { Ask::Auth.resolve(:anything) }
  end

  def test_default_configuration_has_all_five_providers
    config = Ask::Auth.configuration
    assert_equal 5, config.providers.size
  end

  def test_configuration_is_frozen_after_configure
    Ask::Auth.configure { |c| c.providers = [stub("p", call: "v")] }
    assert Ask::Auth.configuration.frozen?
  end

  # ── error classes ──

  def test_missing_credential_message_includes_name
    error = Ask::Auth::MissingCredential.new(:github_token)
    assert_match(/github_token/, error.message)
  end

  def test_invalid_credential_message_includes_name
    error = Ask::Auth::InvalidCredential.new(:github_token)
    assert_match(/github_token/, error.message)
  end

  def test_invalid_credential_accepts_custom_reason
    error = Ask::Auth::InvalidCredential.new(:api_key, "revoked")
    assert_match(/revoked/, error.message)
  end

  # ── reset ──

  def test_reset_configuration_restores_defaults
    Ask::Auth.configure { |c| c.providers = [] }
    Ask::Auth.reset_configuration!

    refute_empty Ask::Auth.configuration.providers
  end
end
