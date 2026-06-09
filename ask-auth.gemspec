require_relative "lib/ask/auth/version"

Gem::Specification.new do |spec|
  spec.name = "ask-auth"
  spec.version = Ask::Auth::VERSION
  spec.authors = ["Kaka Ruto"]
  spec.email = ["kaka@myrrlabs.com"]

  spec.summary = "Credential resolution for the ask-rb ecosystem"
  spec.description = "Env, file, Rails credentials, database, and OAuth providers. Zero external dependencies."
  spec.homepage = "https://github.com/ask-rb/ask-auth"
  spec.license = "MIT"

  spec.required_ruby_version = ">= 3.2"

  spec.files = Dir["lib/**/*", "LICENSE.txt", "README.md"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "minitest", "~> 5.25"
  spec.add_development_dependency "mocha", "~> 3.1"
  spec.add_development_dependency "rake", "~> 13.0"
end
