# frozen_string_literal: true

require_relative "../test_helper"

class EnvProviderTest < Minitest::Test
  def setup
    @provider = Ask::Auth::Providers::Env.new
    @original_env = ENV.to_h
  end

  def teardown
    ENV.clear
    @original_env.each { |k, v| ENV[k] = v }
  end

  def test_resolves_uppercase_underscore
    ENV["GITHUB_TOKEN"] = "gh-secret"
    assert_equal "gh-secret", @provider.call("github_token")
  end

  def test_resolves_uppercase_no_underscore
    ENV["GITHUBTOKEN"] = "compact-secret"
    assert_equal "compact-secret", @provider.call("github_token")
  end

  def test_resolves_exact_case
    ENV["github_token"] = "exact-secret"
    assert_equal "exact-secret", @provider.call("github_token")
  end

  def test_returns_nil_when_not_set
    assert_nil @provider.call("nonexistent_key")
  end

  def test_prefers_uppercase_underscore_over_compact
    ENV["GITHUB_TOKEN"] = "preferred"
    ENV["GITHUBTOKEN"] = "fallback"
    ENV["github_token"] = "last"

    assert_equal "preferred", @provider.call("github_token")
  end

  def test_handles_string_name
    ENV["MY_KEY"] = "value"
    assert_equal "value", @provider.call("my_key")
  end
end
