# frozen_string_literal: true

require_relative "../test_helper"

class RailsCredentialsProviderTest < Minitest::Test
  def setup
    @provider = Ask::Auth::Providers::RailsCredentials.new
    @rails_saved = defined?(::Rails) ? ::Rails : nil
  end

  def teardown
    if @rails_saved
      Object.const_set(:Rails, @rails_saved) unless defined?(::Rails)
    elsif defined?(::Rails)
      Object.send(:remove_const, :Rails)
    end
  end

  def test_returns_nil_when_rails_not_defined
    if defined?(::Rails)
      Object.send(:remove_const, :Rails)
    end
    assert_nil @provider.call(:github_token)
  end

  def test_resolves_by_underscore_path
    creds = Object.new
    def creds.github
      obj = Object.new
      def obj.token; "gh-secret"; end
      obj
    end
    def creds.respond_to?(method)
      {github: true}.fetch(method) { super }
    end

    rails = Object.new
    def rails.application
      app = Object.new
      def app.credentials
        creds = Object.new
        def creds.github
          obj = Object.new
          def obj.token; "gh-secret"; end
          obj
        end
        def creds.respond_to?(method)
          {github: true}.fetch(method) { super }
        end
        creds
      end
      app
    end

    Object.const_set(:Rails, rails) unless defined?(::Rails)

    assert_equal "gh-secret", @provider.call(:github_token)
  end

  def test_returns_nil_when_path_part_missing
    creds = Object.new
    def creds.respond_to?(method)
      false
    end

    rails = Object.new
    def rails.application
      app = Object.new
      def app.credentials
        creds = Object.new
        def creds.respond_to?(method)
          false
        end
        creds
      end
      app
    end

    Object.const_set(:Rails, rails) unless defined?(::Rails)

    assert_nil @provider.call(:nonexistent_key)
  end
end
