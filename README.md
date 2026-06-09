# ask-auth

Credential resolution for the ask-rb ecosystem. A single API for resolving credentials
across all tools and service gems: `Ask::Auth.resolve(:github_token)`.

The resolution chain walks configured providers in order (Env → File → RailsCredentials → Database → OAuth)
and returns the first match. No more reimplementing `ENV["WHATEVER"]` in every gem.

## Installation

```ruby
gem "ask-auth"
```

## Usage

```ruby
# Simple — works everywhere, no config needed
token = Ask::Auth.resolve(:github_token)

# With configuration
Ask::Auth.configure do |c|
  c.providers = [
    Ask::Auth::Env.new,
    Ask::Auth::File.new(path: "~/.ask/credentials.yml"),
    Ask::Auth::RailsCredentials.new
  ]
end
```

## Development

```bash
bin/setup
bundle exec rake test
```

## License

MIT
