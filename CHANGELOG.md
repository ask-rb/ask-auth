## [0.2.3] — 2026-07-18

### Fixed

- **`Providers::File#call` and `Providers::Env#call` safely return nil for Array names** — When `resolve` passes Array path segments (e.g., `[:opencode, :api_key]`), providers that don't support nested lookups now return nil instead of crashing on `.to_sym`.

## [0.2.2] — 2026-07-18

### Fixed

- **`Providers::RailsCredentials` checks value, not just `respond_to?`** — `ActiveSupport::OrderedOptions#respond_to?` returns `true` for any method name. The provider now checks the actual returned value before returning it.

## [0.2.1] — 2026-07-18

### Added

- **`resolve(*names)` supports Array path segments for nested lookups** — Callers can pass Symbol/String for flat lookup or an Array for path segments:
  ```ruby
  Ask::Auth.resolve(:opencode_api_key)
  Ask::Auth.resolve(:opencode_go_api_key, [:opencode, :api_key])
  ```

## [0.2.0] — 2026-07-18

### Added

- **`resolve(*names)` now accepts multiple credential names** — Tries each name in order through the provider chain, returns the first match. Backward-compatible with single-name calls.

### Fixed

- **`MissingCredential` shows all tried names** — Error message lists all credential names attempted.

## [0.1.4] — 2026-07-18

### Added

- **`Providers::RailsCredentials` progressive split strategy** — Tries progressively shorter left splits for credential names like `nvidia_nim_api_key`.

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
