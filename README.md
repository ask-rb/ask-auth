# ask-auth

[![Gem Version](https://badge.fury.io/rb/ask-auth.svg)](https://badge.fury.io/rb/ask-auth)

Credential resolution for the ask-rb ecosystem. A single API for resolving credentials across all ask-rb gems: service gems call `Ask::Auth.resolve(:github_token)` and never touch env vars, files, or OAuth flows directly. Zero external dependencies.

## Installation

```ruby
gem "ask-auth"
```

## Quick Start

```ruby
require "ask-auth"

token = Ask::Auth.resolve(:github_token)
# => "ghp_abc123..."

# Per-user credentials (Database, OAuth providers)
token = Ask::Auth.resolve(:openai_api_key, user: current_user)
```

`resolve` walks the provider chain in order and returns the first match, or raises `Ask::Auth::MissingCredential`. Multiple names can be given for fallbacks, and arrays of symbols resolve nested paths (e.g. `resolve([:opencode, :api_key])`).

## Resolution chain

1. **Env**: environment variables (`ENV["GITHUB_TOKEN"]`)
2. **File**: `~/.ask/credentials.yml`
3. **RailsCredentials**: `Rails.application.credentials` (when Rails is loaded)
4. **Database**: ActiveRecord-backed per-user token storage (when ActiveRecord is loaded)
5. **OAuth**: interactive PKCE flow (returns nil by default, requires explicit authorization)

## Configuration

```ruby
Ask::Auth.configure do |c|
  c.providers = [
    Ask::Auth::Providers::Env.new,
    Ask::Auth::Providers::File.new(path: "~/.myapp/creds.yml"),
    Ask::Auth::Providers::Database.new(model: AccessToken)
  ]
end
```

Any object responding to `call(name, user:)` can act as a provider. Once configured, the resolution chain is frozen and thread-safe.

## Full documentation

The full ask-rb documentation lives at https://ask-rb.github.io/ask-docs. [ask-auth in depth](https://ask-rb.github.io/ask-docs/core/auth) covers each provider, the OAuth flow, and error handling. API reference: https://ask-rb.github.io/ask-docs/reference/api.

## Development

```
bundle install
bundle exec rake test
```

## License

MIT
