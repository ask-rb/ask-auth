# frozen_string_literal: true

require_relative "../test_helper"

class DatabaseProviderTest < Minitest::Test
  def setup
    @provider = Ask::Auth::Providers::Database.new
  end

  def test_returns_nil_when_no_model
    assert_nil @provider.call(:github_token)
  end

  def test_returns_nil_without_user
    assert_nil @provider.call(:github_token, user: nil)
  end

  def test_custom_model_returns_nil_when_not_found
    fake_model = stub("Credential")
    fake_model.stubs(:find_by).with(user_id: 42, name: "github_token").returns(nil)

    provider = Ask::Auth::Providers::Database.new(model: fake_model)
    user = Object.new.tap { |o| o.define_singleton_method(:id) { 42 } }
    assert_nil provider.call("github_token", user: user)
  end

  def test_returns_token_from_record
    record = Object.new
    record.define_singleton_method(:token) { "gh-secret" }
    record.define_singleton_method(:expired?) { false }

    fake_model = stub("Credential")
    fake_model.stubs(:find_by).with(user_id: 1, name: "github_token").returns(record)

    provider = Ask::Auth::Providers::Database.new(model: fake_model)
    user = Object.new.tap { |o| o.define_singleton_method(:id) { 1 } }
    assert_equal "gh-secret", provider.call("github_token", user: user)
  end

  def test_refreshes_expired_token
    refreshed = false
    record = Object.new
    record.define_singleton_method(:token) { "refreshed-token" }
    record.define_singleton_method(:expired?) { true }
    record.define_singleton_method(:refresh!) { refreshed = true }
    record.define_singleton_method(:reload) { nil }

    fake_model = stub("Credential")
    fake_model.stubs(:find_by).with(user_id: 1, name: "github_token").returns(record)

    provider = Ask::Auth::Providers::Database.new(model: fake_model)
    user = Object.new.tap { |o| o.define_singleton_method(:id) { 1 } }
    assert_equal "refreshed-token", provider.call("github_token", user: user)
    assert refreshed, "expected refresh! to be called"
  end

  def test_returns_nil_when_expired_and_no_refresh
    record = Object.new
    record.define_singleton_method(:token) { "secret" }
    record.define_singleton_method(:expired?) { true }
    # No refresh! method — respond_to?(:refresh!) returns false

    fake_model = stub("Credential")
    fake_model.stubs(:find_by).with(user_id: 1, name: "github_token").returns(record)

    provider = Ask::Auth::Providers::Database.new(model: fake_model)
    user = Object.new.tap { |o| o.define_singleton_method(:id) { 1 } }
    assert_nil provider.call("github_token", user: user)
  end

  def test_accepts_custom_model_class
    my_model = Class.new
    provider = Ask::Auth::Providers::Database.new(model: my_model)
    assert_equal my_model, provider.model
  end
end
