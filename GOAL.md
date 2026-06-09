# ask-auth — Credential Resolution

## Purpose

A single API for resolving credentials across all ask-rb gems. Service gems call `Ask::Auth.resolve(:github_token)` — they never touch env vars, files, or OAuth flows directly. The resolution chain walks configured providers in order (Env → File → RailsCredentials → Database → OAuth) and returns the first match.

Zero external dependencies for the core. Optional ActiveRecord integration for database-backed token storage.

## Dependencies

- **Runtime:** none (stdlib only — `YAML`, `File`, `ENV`)
- **Optional:** `ActiveRecord` (for `Database` provider — not required for gem installation)
- **Build/test:** minitest, mocha, rake, tempfile
- **No other ask-rb gems required.** This gem is independent of the tool/agent stack.

## Implementation Steps

### 1. Define the gem scaffold
- `lib/ask-auth.rb` — entry point
- `lib/ask/auth.rb` — main module with `.configure`, `.resolve`, provider registration
- `lib/ask/auth/version.rb`
- `ask-auth.gemspec` — zero runtime deps

### 2. Build configuration system
- `Ask::Auth.configure { |c| c.providers = [...] }` — block-based config
- `Ask::Auth.resolve(name, user: nil)` — walks providers, returns first non-nil value
- `Ask::Auth::MissingCredential` error (raised when all providers return nil)
- `Ask::Auth::InvalidCredential` error (raised when a token is rejected at usage time)
- Blank normalization: config values set to empty string are normalized to `nil`

### 3. Build providers (one file per provider)

**`Ask::Auth::Env`** (`lib/ask/auth/providers/env.rb`)
- Resolves from environment variables by convention
- Tries multiple naming styles: `GITHUB_TOKEN`, `GITHUBTOKEN`, `github_token`
- No configuration needed — just convention

**`Ask::Auth::File`** (`lib/ask/auth/providers/file.rb`)
- Reads from a YAML file (default: `~/.ask/credentials.yml`)
- Creates file with `chmod 0600` on write
- Resolves by key lookup: `{github_token: "..."}`

**`Ask::Auth::RailsCredentials`** (`lib/ask/auth/providers/rails_credentials.rb`)
- Wraps `Rails.application.credentials`
- Convention: `:github_token` looks up `credentials.github.token`
- Must check `defined?(Rails)` before accessing

**`Ask::Auth::Database`** (`lib/ask/auth/providers/database.rb`)
- ActiveRecord-backed token storage per user
- Expects model with `user_id`, `name`, `token`, `expires_at`, `refresh_token`
- Handles expiry: if `expired?`, calls `refresh!` using stored refresh token
- Only loaded if ActiveRecord is defined (optional dependency)

**`Ask::Auth::OAuth`** (`lib/ask/auth/providers/oauth.rb`)
- PKCE OAuth flow for interactive auth
- Methods: `authorize_url(user:)` returns redirect URL, `authorize!(user:, code:)` exchanges code for token
- Stores result in a configured storage provider (typically Database)
- Uses `base64` and `openssl` for PKCE (stdlib)
- Note: this can be deferred to a later release — wire the interface now, implement fully when OAuth is needed

### 4. Test coverage
- Test resolve chain walks providers in order
- Test each provider independently with mock storage/file/env
- Test blank normalization: `""` → `nil`
- Test `MissingCredential` error message includes helpful instructions
- Test `File` provider creates file with correct permissions
- Test `Database` provider expiry + refresh flow
- Test `Env` provider convention matching
- Test `configure` with invalid providers raises clear error

### 5. README
- Quick start: `Ask::Auth.resolve(:github_token)` and `Ask::Auth.configure`
- Each provider documented with configuration example
- Credential file format documented
- Rails integration guide
- Adding custom providers

### 6. Production hardening
- File provider creates credentials file with `0600` permissions
- File provider has configurable path (no hardcoded assumptions)
- Database provider handles missing model gracefully
- Thread-safe resolution (configuration should be immutable after boot)
- Sensible error messages for every failure mode

## What "Done" Means

- `Ask::Auth.resolve(:name)` returns credential from configured chain
- All 5 providers implemented (OAuth can be deferred — implement the interface, full flow later)
- Blank config values normalize to `nil`
- `MissingCredential` and `InvalidCredential` errors with helpful messages
- >90% test coverage
- File provider creates `~/.ask/credentials.yml` with `0600` permissions
- README documents all providers and common patterns
- Service gems can be written against this API immediately
