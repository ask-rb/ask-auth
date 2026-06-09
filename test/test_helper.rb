# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

begin
  require "simplecov"
  SimpleCov.start do
    add_filter "/test/"
    add_filter "/vendor/"
    minimum_coverage 90
  end
rescue LoadError
  # SimpleCov is optional
end

require "minitest/autorun"
require "mocha/minitest"
require "tempfile"
require "yaml"

require "ask-auth"
