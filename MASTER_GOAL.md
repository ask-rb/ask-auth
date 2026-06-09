# MASTER_GOAL.md — ask-auth

## Purpose

This is the **master goal** for building ask-auth. It does not implement the gem
directly. It loads and follows the detailed build plan at:

> **GOAL.md:** `/Users/kaka/Code/ask-rb/ask-auth/GOAL.md`

## How To Use This Goal

1. Open the GOAL.md at the path above
2. Follow every section in order: Purpose, Dependencies, Implementation Steps, Testing, Release
3. Do NOT deviate from the plan — every step is documented for a reason
4. When done, verify against the Release Checklist at the bottom of GOAL.md
5. Report completion status back to this master goal

## Context

All ask-rb gem repos are available locally at `/Users/kaka/Code/ask-rb/`.
Key reference projects for this gem to study:

- **Source:** `/Users/kaka/Code/ask-rb/ask-auth/lib/`
- **Tests:** `/Users/kaka/Code/ask-rb/ask-auth/test/`
- **Goal:** `/Users/kaka/Code/ask-rb/ask-auth/GOAL.md`
- **Remote:** `git@github.com:ask-rb/ask-auth.git`
- **Ruby stdlib only** (YAML, File, ENV)

## Dependencies
This gem has zero runtime dependencies and can be built independently.

## Build Steps (Outline)

The GOAL.md at `/Users/kaka/Code/ask-rb/ask-auth/GOAL.md` contains the full
implementation steps. Follow it in order. Key milestones:

1. Define gem scaffold (gemspec, entry point, version)
2. Implement core classes per GOAL.md
3. Write tests for every public method
4. Run full test suite — fix all failures
5. Verify Release Checklist
6. Build and release as private gem

## Release Checklist (from GOAL.md)

See the bottom of `/Users/kaka/Code/ask-rb/ask-auth/GOAL.md` for the full checklist.

## Completion

When done, this gem reaches v0.1.0:
- All tests pass (>90% coverage)
- Gem builds without errors
- Released as private gem on GitHub Packages
- README is complete
- CHANGELOG.md exists with v0.1.0 entry
- ask-docs is updated (if applicable)
