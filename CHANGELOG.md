# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.0.0] - 2026-05-28

### Breaking
- **Ruby ≥ 3.0 required.** Customers on Ruby 2.6 or 2.7 should pin to `~> 1.0` in their `Pluginfile`.

### Fixed
- `fastlane action upload_to_testappio` (the help/docs introspection command) no longer crashes with `NameError`. A `nill` typo in `return_value` was breaking this introspection path — actual uploads were unaffected, but Fastlane's plugin docs couldn't render.
- `validate_file_path` no longer raises `TypeError` when `apk_file` or `ipa_file` is `nil` — affected iOS-only and Android-only lanes that didn't set the other file param.
- `handle_error` no longer fails the upload when `ta-cli` writes warning or info lines to stderr — only real `Error:` lines fail the lane now.
- `--api_token` is now masked (`********`) in verbose-mode command logging — previously the token was echoed in plain text via `UI.command` in `fastlane --verbose` runs.

### Added
- `spec.description` and `spec.metadata` (rubygems_mfa_required, source_code_uri, changelog_uri, bug_tracker_uri) in gemspec.
- Test coverage raised from 36.79% → **100% line / 86.76% branch** (49 unit + 2 opt-in `:integration` specs exercise the real `ta-cli` binary).
- Concurrent stdout/stderr reading in `call_ta_cli` via threads — prevents potential deadlock when ta-cli emits a large stderr buffer before stdout completes. Threads are cleanly killed in an `ensure` block if the surrounding popen3 block raises.
- `Open3.popen3` now uses the array form (no shell interpretation), so shell metacharacters in `api_token` / `release_notes` / file paths are passed literally to ta-cli without depending on manual escaping.
- `handle_error` now includes the actual `/Error/`-matching stderr lines in the raised `FastlaneError` message so users see the real failure reason in their CI logs.
- Shared spec helpers in `spec/spec_helper.rb` for stubbing `Open3.popen3` and `FastlaneCore::Globals.verbose?`.
- SimpleCov `minimum_coverage line: 95, branch: 90` gate (CI-only — local single-file runs no longer trip the gate).
- Opt-in `:integration` spec suite in `spec/integration/` — runs the real `ta-cli` binary against `fastlane/sample/*` with fake credentials to verify the deploy flow end-to-end. Run with `bundle exec rspec --tag integration` or `INTEGRATION=1 bundle exec rspec`.
- GitHub Actions CI: matrix over Ruby 3.0–3.3 × ubuntu/macos, with separate lint, test, and build jobs.
- Codecov coverage upload (via simplecov-cobertura) from one matrix cell.
- Tag-triggered `release.yml` workflow that builds and pushes the gem to RubyGems.
- Dependabot config for bundler and github-actions ecosystems.
- README badges: CI status, Codecov coverage, downloads, license, Ruby version, plus a Compatibility section.
- `self_update: true` example in `fastlane/Fastfile`.

### Changed
- `rubocop` bumped from `1.12.1` to `~> 1.50` (dependent gems aligned).
- `simplecov`, `pry`, `fastlane`, `rspec_junit_formatter` bumped to current majors.
- `.rubocop.yml` `TargetRubyVersion` raised to `3.0`; deprecated cop names updated.

### Removed
- `.travis.yml` and `.circleci/config.yml` (both obsolete; replaced by GitHub Actions).
- `spec.test_files` from gemspec (deprecated by RubyGems).
- `rubocop-require_tools` dev dependency (covered by rubocop 1.50+).

## [1.0.5] - 2023-04-27

### Changed
- Update Fastlane plugin link in README.

## [1.0.4] - 2023

### Changed
- Internal param refinement and result printing.

## [1.0.3] - 2022

### Changed
- Rolled back to v2 tag of ta-cli.

[Unreleased]: https://github.com/testappio/fastlane-plugin-testappio/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/testappio/fastlane-plugin-testappio/compare/v1.0.5...v2.0.0
[1.0.5]: https://github.com/testappio/fastlane-plugin-testappio/compare/v1.0.4...v1.0.5
[1.0.4]: https://github.com/testappio/fastlane-plugin-testappio/compare/v1.0.3...v1.0.4
[1.0.3]: https://github.com/testappio/fastlane-plugin-testappio/releases/tag/v1.0.3
