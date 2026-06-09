# frozen_string_literal: true

require_relative "../test_helper"

class FileProviderTest < Minitest::Test
  def setup
    @tempfile = Tempfile.new(["credentials", ".yml"])
    @tempfile.write(YAML.dump({github_token: "gh-secret", openai_key: "sk-123"}))
    @tempfile.close

    @provider = Ask::Auth::Providers::File.new(path: @tempfile.path)
  end

  def teardown
    @tempfile.unlink
  end

  def test_resolves_from_yaml_by_string_key
    assert_equal "gh-secret", @provider.call("github_token")
  end

  def test_resolves_from_yaml_by_symbol_key
    assert_equal "gh-secret", @provider.call(:github_token)
  end

  def test_returns_nil_for_missing_key
    assert_nil @provider.call("nonexistent")
  end

  def test_returns_nil_when_file_does_not_exist
    provider = Ask::Auth::Providers::File.new(path: "/tmp/nonexistent_creds.yml")
    assert_nil provider.call("anything")
  end

  def test_returns_nil_when_file_has_invalid_yaml
    bad_file = Tempfile.new(["bad", ".yml"])
    bad_file.write("{{invalid yaml\n")
    bad_file.close

    provider = Ask::Auth::Providers::File.new(path: bad_file.path)
    assert_nil provider.call("key")
  ensure
    bad_file&.unlink
  end

  def test_returns_nil_when_file_is_empty
    empty_file = Tempfile.new(["empty", ".yml"])
    empty_file.close

    provider = Ask::Auth::Providers::File.new(path: empty_file.path)
    assert_nil provider.call("key")
  ensure
    empty_file&.unlink
  end

  def test_configurable_path
    provider = Ask::Auth::Providers::File.new(path: "/custom/path.yml")
    assert_equal "/custom/path.yml", provider.path
  end

  def test_default_path
    provider = Ask::Auth::Providers::File.new
    assert_equal Ask::Auth::Providers::File::DEFAULT_PATH, provider.path
  end
end
