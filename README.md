# [<img src="https://assets.testapp.io/logo/blue.svg" alt="TestApp.io"/>](https://testapp.io/) Fastlane Plugin

Upload your Android (`.apk`) and iOS (`.ipa`) builds to [TestApp.io](https://testapp.io) straight from your Fastlane lane. One action, both platforms, release notes from git, optional team notifications.

[![fastlane Plugin Badge](https://rawcdn.githack.com/fastlane/fastlane/master/fastlane/assets/plugin-badge.svg)](https://rubygems.org/gems/fastlane-plugin-testappio)
[![Gem Version](https://img.shields.io/gem/v/fastlane-plugin-testappio)](https://rubygems.org/gems/fastlane-plugin-testappio)
[![CI](https://github.com/testappio/fastlane-plugin-testappio/actions/workflows/ci.yml/badge.svg)](https://github.com/testappio/fastlane-plugin-testappio/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/testappio/fastlane-plugin-testappio/branch/main/graph/badge.svg)](https://codecov.io/gh/testappio/fastlane-plugin-testappio)
[![Downloads](https://img.shields.io/gem/dt/fastlane-plugin-testappio)](https://rubygems.org/gems/fastlane-plugin-testappio)
[![License](https://img.shields.io/github/license/testappio/fastlane-plugin-testappio)](LICENSE)
[![Ruby](https://img.shields.io/badge/ruby-%3E%3D%203.0-CC342D.svg)](https://www.ruby-lang.org/)

---

## Install

```bash
fastlane add_plugin testappio
```

That's it. The plugin will install the underlying [`ta-cli`](https://help.testapp.io/ta-cli/) binary the first time you upload.

## Quick start

```ruby
lane :beta do
  gym(export_method: "ad-hoc")        # or gradle(task: "assembleRelease")

  upload_to_testappio(
    api_token: ENV["TESTAPPIO_API_TOKEN"],
    app_id:    ENV["TESTAPPIO_APP_ID"],
    notify:    true
  )
end
```

Get your `api_token` at <https://portal.testapp.io/profile/tokens>.
Get your `app_id` at <https://portal.testapp.io/apps>.

## Configuration

| Key | Description | Env var | Default |
|---|---|---|---|
| `api_token` | API token from <https://portal.testapp.io/profile/tokens> | `TESTAPPIO_API_TOKEN` | — |
| `app_id` | App ID from your <https://portal.testapp.io/apps> page | `TESTAPPIO_APP_ID` | — |
| `release` | `ios`, `android`, or `both` | `TESTAPPIO_RELEASE` | current platform |
| `apk_file` | Path to the Android `.apk` | `TESTAPPIO_ANDROID_PATH` | gradle's output |
| `ipa_file` | Path to the iOS `.ipa` | `TESTAPPIO_IOS_PATH` | gym's output |
| `release_notes` | Manual release notes | `TESTAPPIO_RELEASE_NOTES` | — |
| `git_release_notes` | Use the latest git commit message as release notes | `TESTAPPIO_GIT_RELEASE_NOTES` | `true` |
| `git_commit_id` | Append the latest commit SHA to the release notes | `TESTAPPIO_GIT_COMMIT_ID` | `false` |
| `notify` | Notify team members about the new release | `TESTAPPIO_NOTIFY` | `false` |
| `self_update` | Auto-update `ta-cli` when a new version is available | `TESTAPPIO_SELF_UPDATE` | `true` |

## Examples

### iOS only

```ruby
lane :beta_ios do
  match(type: "adhoc")
  gym(export_method: "ad-hoc")

  upload_to_testappio(
    api_token:     ENV["TESTAPPIO_API_TOKEN"],
    app_id:        ENV["TESTAPPIO_APP_ID"],
    release:       "ios",
    release_notes: "Bug fixes and improvements",
    notify:        true
  )
end
```

### Android only

```ruby
lane :beta_android do
  gradle(task: "clean assembleRelease")

  upload_to_testappio(
    api_token:         ENV["TESTAPPIO_API_TOKEN"],
    app_id:            ENV["TESTAPPIO_APP_ID"],
    release:           "android",
    git_release_notes: true,
    git_commit_id:     true,
    notify:            true
  )
end
```

### Both platforms in one lane

```ruby
lane :beta_both do
  gradle(task: "clean assembleRelease")
  gym(export_method: "ad-hoc")

  upload_to_testappio(
    api_token: ENV["TESTAPPIO_API_TOKEN"],
    app_id:    ENV["TESTAPPIO_APP_ID"],
    release:   "both",
    notify:    true
  )
end
```

A runnable example lives in [`fastlane/Fastfile`](fastlane/Fastfile). Try it with `bundle exec fastlane test`.

## Compatibility

| Plugin version | Ruby | Status |
|---|---|---|
| **2.x** | `>= 3.0` | Active — feature work + security fixes |
| **1.x** | `>= 2.6` | Maintenance only — security fixes through May 2027 |

If your CI image uses Ruby 2.6 or 2.7, pin to `~> 1.0` in your `Pluginfile`:

```ruby
gem "fastlane-plugin-testappio", "~> 1.0"
```

When you upgrade your CI to Ruby 3.0+, drop the pin and you'll get 2.x automatically.

## Troubleshooting

- **`fastlane add_plugin testappio` fails on Bundler 2.0 issues** — make sure your Ruby is 3.0 or higher (`ruby -v`).
- **Upload fails with a `ta-cli` error** — the error message now includes the underlying `ta-cli` output so you can see exactly what went wrong (auth, network, provisioning, etc.). Run with `fastlane --verbose` for full context.
- **Token visible in CI logs** — should never happen in 2.x; tokens are masked as `********`. If you see this in 1.x, upgrade.
- **Other plugin issues** — see the official [Fastlane plugin troubleshooting guide](https://docs.fastlane.tools/plugins/plugins-troubleshooting/).

## Contributing

PRs welcome. Local development:

```bash
bundle install                  # install dev dependencies
bundle exec rspec               # run the unit test suite (49 specs)
bundle exec rubocop             # lint
bundle exec rake                # spec + rubocop together
INTEGRATION=1 bundle exec rspec # also run the 2 :integration specs (needs ta-cli installed)
```

Every PR adds an entry under `## [Unreleased]` in [`CHANGELOG.md`](CHANGELOG.md). See it for the full list of what changed between versions.

## Feedback & support

- **Help center:** <https://help.testapp.io/>
- **Community:** <https://help.testapp.io/faq/join-our-community/>
- **Bug reports / feature requests:** [GitHub issues](https://github.com/testappio/fastlane-plugin-testappio/issues)

Built by [TestApp.io](https://testapp.io) — happy releasing 🚀
