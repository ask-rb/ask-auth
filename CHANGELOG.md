## [0.1.1] - 2026-06-25

### Changed
- Infrastructure: rubocop, overcommit, bin/setup, CI matrix, gemspec test, SimpleCov, .minitest config.
# Changelog

## [0.1.0] — 2026-06-09

Initial release of `ask-auth`, the credential resolution gem for the ask-rb ecosystem.

### Added

- **Configuration system** — `Ask::Auth.configure` with block-based config and frozen post-boot safety
- **Resolution chain** — `Ask::Auth.resolve(name, user: nil)` walks providers in order, returns first non-nil
- **Blank normalization** — empty string and whitespace-only values normalize to `nil`
- **Error classes** — `MissingCredential` and `InvalidCredential` with actionable messages
- **Env provider** — resolves from `ENV` by convention (`GITHUB_TOKEN`, `GITHUBTOKEN`, `github_token`)
- **File provider** — reads `~/.ask/credentials.yml` with configurable path and Symbol-safe YAML loading
- **RailsCredentials provider** — wraps `Rails.application.credentials` with safe nil when Rails not loaded
- **Database provider** — ActiveRecord-backed per-user token storage with automatic expiry + refresh
- **OAuth provider** — PKCE interface with `authorize_url` and `authorize!` methods (full flow deferred)
- **Test suite** — 45 tests, 99%+ coverage across all providers and the resolution chain
- **Thread safety** — configuration is frozen after `configure` completes
