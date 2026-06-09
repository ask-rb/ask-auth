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

## Documentation

### Documentation
- **Update ask-docs** after releasing v0.1.0 — the docs site at github.com/ask-rb/ask-docs must reflect this gems API, usage, and position in the ecosystem.
- The ask-docs repo has a Jekyll site with sections for each gem under core/, providers/, tools/, agent/.
- Add or update the relevant page(s) and submit a PR to ask-docs.
- This is not optional — ask-docs is the public face of the ecosystem.

## Release Checklist (Required for v0.1.0)

Before declaring this gem done and releasing v0.1.0, verify:

- [] All tests pass with >90% coverage
- [] Every public API method has documentation (yardoc or inline comments)
- [] README is complete: installation, quick start, configuration, development
- [] CHANGELOG.md exists with an entry for v0.1.0
- [] All code is committed and pushed to github.com/ask-rb/ask-auth
- [] Gem builds without errors: gem build *.gemspec
- [] Gem is released on RubyGems
- [] A consumer app can install, require, and use the gem with no errors
- [] Thread-safety verified (registry, config, client construction)
- [] Error messages are helpful and actionable

## What Done Means for v0.1.0

The gem reaches v0.1.0 when:
- All implementation steps above are complete and tested
- The gem is released on RubyGems
- A real consumer can install it with gem install or Bundler
- A consumer script can require it and use its full public API
- The README provides enough information for someone unfamiliar to get started in 5 minutes
- The CHANGELOG documents what v0.1.0 delivers

## Development Workflow

### Git conventions
- The default branch is **master**. All work should be based on master unless a specific branch is requested.

- Follow the git-workflow skill for branch naming, commit messages, and PR structure.
- Use conventional commits: `feat:`, `fix:`, `docs:`, `test:`, `refactor:`, `chore:`.
- One logical change per commit. No "fixup" or "wip" commits on master.
- Commit messages must be one direct sentence describing the change.

### Reference projects
Study existing implementations for patterns and conventions:

- **ask-tools-shell** — extract from `ruby_llm-conductor/lib/ruby_llm/conductor/tools/`
- **ask-agent** — port from `ruby_llm-conductor/` (session, loop, tool_executor, compactor, etc.)
- **ask-rails** — transform from `solid_agents/` (railtie, generators, persistence)
- **ask-openai, ask-anthropic** — study `ruby_llm/lib/ruby_llm/providers/` for wire formats and streaming patterns
- **ask-openai** — also study `llm-proxy/lib/llm_proxy/protocols/` for OpenAI protocol conversion
- **General patterns** — study `pi/packages/ai/src/providers/` for lazy loading, registration, and protocol families
- **Test patterns** — study `ruby_llm/spec/` for VCR cassette structure and integration testing patterns
- **ask-github** — reference implementation for service context gems; follow its three-file pattern
### Reference Repositories (Local)
All ask-rb gem repos are available locally at /Users/kaka/Code/ask-rb/ for reference.
Do not clone from GitHub — use the local directories:
- Source code: /Users/kaka/Code/ask-rb/GEMNAME/lib/
- Tests: /Users/kaka/Code/ask-rb/GEMNAME/test/
- Goal: /Users/kaka/Code/ask-rb/GEMNAME/GOAL.md
- Gemspec: /Users/kaka/Code/ask-rb/GEMNAME/GEMNAME.gemspec

Other reference projects in the same workspace:
- /Users/kaka/Code/ask-rb/ruby_llm/ — RubyLLM gem (providers, models, streaming)
- /Users/kaka/Code/ask-rb/ruby_llm-conductor/ — Original conductor (agent loop, tools)
- /Users/kaka/Code/ask-rb/llm-proxy/ — Protocol normalization patterns
- /Users/kaka/Code/ask-rb/pi/ — Pi agent (TypeScript, provider architecture)
- /Users/kaka/Code/ask-rb/solid_agents/ — Original solid_agents (Rails engine)
- /Users/kaka/Code/ask-rb/composio/ — Composio SDK (MCP tool execution examples)
- /Users/kaka/Code/ask-rb/ask-docs/ — Documentation site (update after release)

### Testing
- Use Minitest (not RSpec) — consistent with the ask-rb ecosystem.
- Unit tests for every public method (normal path + edge cases + error cases).
- Integration tests with VCR cassettes for any gem that calls external APIs.
- Run the full suite before every commit: `bundle exec rake test`.
