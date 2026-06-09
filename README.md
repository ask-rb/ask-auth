# ask-auth

**Credential resolution for the ask-rb ecosystem.**

A single API for resolving credentials across all ask-rb gems. Service gems call `Ask::Auth.resolve(:github_token)` — they never touch env vars, files, or OAuth flows directly. The resolution chain walks configured providers in order and returns the first match.

Zero external dependencies for the core. Optional ActiveRecord integration for database-backed token storage.

## Installation

Add this line to your Gemfile:

```ruby
gem "ask-auth"
```

Or install it directly:

```bash
gem install ask-auth
```

## Quick Start

```ruby
require "ask-auth"

# Simple — works everywhere, no config needed
token = Ask::Auth.resolve(:github_token)
# => "ghp_abc123..."

# With a user context (for per-user providers like Database)
token = Ask::Auth.resolve(:openai_api_key, user: current_user)
```

By default, the resolution chain checks these providers in order:

1. **Env** — environment variables
2. **File** — `~/.ask/credentials.yml`
3. **RailsCredentials** — `Rails.application.credentials` (if Rails is loaded)
4. **Database** — ActiveRecord-backed token storage (if ActiveRecord is loaded)
5. **OAuth** — interactive PKCE flow (returns nil by default — requires explicit authorization)

## Configuration

Customize the provider chain with `Ask::Auth.configure`:

```ruby
Ask::Auth.configure do |c|
  c.providers = [
    Ask::Auth::Providers::Env.new,
    Ask::Auth::Providers::File.new(path: "~/.myapp/creds.yml"),
    Ask::Auth::Providers::Database.new(model: AccessToken)
  ]
end
```

Once configured, the resolution chain is frozen and thread-safe.

## Providers

### Env (`Ask::Auth::Providers::Env`)

Resolves credentials from environment variables by convention. Tries multiple naming styles:

```ruby
Ask::Auth.resolve(:github_token)
# Checks (in order): ENV["GITHUB_TOKEN"], ENV["GITHUBTOKEN"], ENV["github_token"]
```

No configuration needed.

### File (`Ask::Auth::Providers::File`)

Reads credentials from a YAML file:

```yaml
# ~/.ask/credentials.yml
github_token: ghp_abc123...
openai_api_key: sk-...
```

```ruby
Ask::Auth::Providers::File.new
Ask::Auth::Providers::File.new(path: "~/.custom/credentials.yml")
```

The file is created with `0600` permissions when written (the provider is read-only; use your editor or a setup script).

### RailsCredentials (`Ask::Auth::Providers::RailsCredentials`)

Wraps `Rails.application.credentials`. Converts `snake_case` names to dot-separated paths:

```ruby
Ask::Auth.resolve(:github_token)
# Looks up: Rails.application.credentials.github.token
```

Safely returns nil when Rails is not loaded.

### Database (`Ask::Auth::Providers::Database`)

ActiveRecord-backed token storage per user. Expects a model with `user_id`, `name`, `token`, `expires_at`, and `refresh_token` columns.

```ruby
# app/models/credential.rb
class Credential < ApplicationRecord
  belongs_to :user
end
```

```ruby
Ask::Auth::Providers::Database.new
Ask::Auth::Providers::Database.new(model: AccessToken)
```

Handles token expiry automatically: calls `refresh!` when a token has expired and a `refresh_token` is available.

### OAuth (`Ask::Auth::Providers::OAuth`)

PKCE OAuth flow for interactive credential authorization. This provider does not resolve automatically — it provides the authorization interface:

```ruby
provider = Ask::Auth::Providers::OAuth.new(
  client_id: "your-client-id",
  authorize_url: "https://provider.com/oauth/authorize",
  token_url: "https://provider.com/oauth/token"
)

# Step 1: Generate the authorization URL
url = provider.authorize_url(user: current_user)

# Step 2: Exchange the code for tokens
provider.authorize!(user: current_user, code: params[:code])
```

The full token exchange flow requires configuration. The PKCE utility methods (`generate_code_verifier`, `generate_code_challenge`) are ready for use.

## Custom Providers

Any object that responds to `call(name, user:)` can be a provider:

```ruby
Ask::Auth.configure do |c|
  c.providers = [
    Ask::Auth::Providers::Env.new,
    ->(name, user: nil) { user&.api_key_for(name) }
  ]
end
```

## Error Handling

```ruby
begin
  token = Ask::Auth.resolve(:missing_key)
rescue Ask::Auth::MissingCredential => e
  puts e.message
  # "No credential found for :missing_key. Set MISSING_KEY in your environment..."
end

begin
  # At usage time
  raise Ask::Auth::InvalidCredential.new(:github_token, "rate limited")
rescue Ask::Auth::InvalidCredential => e
  puts e.message
  # "Credential :github_token is rate limited..."
end
```

## Development

```bash
git clone https://github.com/ask-rb/ask-auth
cd ask-auth
bin/setup
bundle exec rake test
```

## License

MIT
