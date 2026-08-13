## [0.3.2] — 2026-08-13

### Added

- **`Ask::Auth.lookup` — non-raising credential resolution.** Same chain and
  fallback semantics as `resolve`, but returns `nil` when nothing matches
  instead of raising `MissingCredential`. For config-time resolution (e.g.
  ERB in `database.yml`) where a missing credential should degrade to
  nil/defaults rather than crash the boot. `resolve` is now implemented on
  top of `lookup` and keeps its raising behavior.

## [0.3.1] — 2026-08-07

### Added

- **Device authorization grant (RFC 8628) OAuth providers.** `Ask::Auth::Providers::DeviceOAuth` base — `start_device_flow` (device + user code from the provider), `complete_device_flow` (long-poll the token endpoint; `PendingAuthorization` until the user authorizes) — plus two providers:
  - `Ask::Auth::Providers::Xai` — xAI/Grok device OAuth (public Grok-CLI client, `auth.x.ai/oauth2`), mirroring opencode's xai.ts.
  - `Ask::Auth::Providers::GithubCopilot` — GitHub Copilot device OAuth (`github.com/login/device/code`), mirroring opencode's copilot.ts. Note: Copilot's device flow is a gray area of GitHub's terms.

## [0.3.0] — 2026-08-07

### Added

- **OpenAI Codex OAuth provider — bring your ChatGPT subscription.** `Ask::Auth::Providers::OpenaiCodex` completes the PKCE flow against `auth.openai.com` (public Codex client id, `openid profile email offline_access` scope): `authorize_url` (with `id_token_add_organizations`), `authorize!` (code exchange → `{token, refresh_token, expires_at, account_id, raw}`), and `refresh(refresh_token:)`. Includes `.allowed_model?` tier filtering (gpt-5.4+ general + codex family; pro-reasoning and gpt-5.6 excluded) and account-id extraction from the id_token — mirroring opencode's codex.ts.
- **Completed OAuth base provider.** `Ask::Auth::Providers::OAuth` now implements the token exchange (`authorize!`) and refresh grants via an injectable stdlib HTTP layer, with optional verifier/state persistence through a `store`/`fetch`-responding storage object. `Ask::Auth::OAuthError` raised on transport/provider failures.
- `Ask::Auth::OAuth::HTTP` — dependency-free form-encoded POST for token endpoints (swappable in tests).

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
