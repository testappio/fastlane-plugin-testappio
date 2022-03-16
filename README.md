# [<img src="https://assets.testapp.io/logo/blue.svg" alt="TestApp.io"/>](https://testapp.io/) Fastlane Plugin


> This is in BETA mode. Your feedback is highly appreciated.

A fastlane plugin to upload both Android & iOS apps to TestApp.io to notify everyone for testing and feedback.

#### Version 1.0

[![fastlane Plugin Badge](https://rawcdn.githack.com/fastlane/fastlane/master/fastlane/assets/plugin-badge.svg)](https://rubygems.org/gems/fastlane-plugin-testappio) [![Gem Version](https://badge.fury.io/rb/fastlane-plugin-testappio.svg)](https://badge.fury.io/rb/fastlane-plugin-testappio)


- [TestApp.io plugin](#testappio-plugin)
  - [Getting started](#getting-started)
  - [TestApp.io actions](#testappio-actions)
    - [Action **upload_to_testappio**](#action-upload_to_testappio)
  - [Issues and feedback](#issues-and-feedback)
  - [Troubleshooting](#troubleshooting)
  - [Using _fastlane_ plugins](#using-fastlane-plugins)
  - [About _fastlane_](#about-fastlane)

## Getting started

This project is a [_fastlane_](https://github.com/fastlane/fastlane) plugin. To get started with `fastlane-plugin-testappio`, add it to your project by running:

```bash
fastlane add_plugin testappio
```

## TestApp.io actions

Actions provided by the CLI: [ta-cli](https://github.com/testappio/cli)

Check out the [example `Fastfile`](fastlane/Fastfile) to see how to use this plugin. Try it by cloning the repo, running `fastlane install_plugins` and `bundle exec fastlane test`.

To upload after the fastlane `gym` action:

```ruby
  lane :development do
    match(type: "development")
    gym(export_method: "development")
    upload_to_testappio(
      api_token: "Your API Token",
      app_id: "Your App ID",
      release: "both",
      apk_file: "/full/path/to/app.apk",
      ipa_file: "/full/path/to/app.ipa",
      release_notes: "release notes go here",
      git_release_notes: true,
      git_commit_id: false,
      notify: false
    )
  end
```

### Action **upload_to_testappio**

Upload Android (APK) & iOS (IPA) files to TestApp.io and notify your team members

| Key               | Description                                                                                             | Env Var(s)                  | Default |
| ----------------- | ------------------------------------------------------------------------------------------------------- | --------------------------- | ------- |
| api_token         | You can get it from https://portal.testapp.io/settings/api-credentials                                  | TESTAPPIO_API_TOKEN         |         |
| app_id            | You can get it from your app page in https://portal.testapp.io/apps                                     | TESTAPPIO_APP_ID            |         |
| release           | It can be either both or android or ios                                                                 | TESTAPPIO_RELEASE           |         |
| apk_file          | Path to the android apk file                                                                            | TESTAPPIO_ANDROID_PATH      |         |
| ipa_file          | Path to the ios ipa file                                                                                | TESTAPPIO_IOS_PATH          |         |
| release_notes     | Manually add the release notes to be displayed for the testers                                          | TESTAPPIO_RELEASE_NOTES     |         |
| git_release_notes | Collect release notes from the latest git commit message to be displayed for the testers: true or false | TESTAPPIO_GIT_RELEASE_NOTES | true    |
| git_commit_id     | Include the last commit ID in the release notes (works with both release notes option): true or false   | TESTAPPIO_GIT_COMMIT_ID     | false   |
| notify            | Send notificaitons to your team members about this release: true or false                               | TESTAPPIO_NOTIFY            | false   |

## Issues and feedback

For any other issues and feedback about this plugin, please submit it to this repository.

Join our [Slack](https://join.slack.com/t/testappio/shared_invite/zt-pvpoj3l2-epGYwGTaV3~3~0f7udNWoA) channel for feedback and support or you can contact us at support@testapp.io and we'll gladly help you out!

## Troubleshooting

If you have trouble using plugins, check out the [Plugins Troubleshooting](https://docs.fastlane.tools/plugins/plugins-troubleshooting/) guide.

## Using _fastlane_ plugins

For more information about how the `fastlane` plugin system works, check out the [Plugins documentation](https://docs.fastlane.tools/plugins/create-plugin/).

## About _fastlane_

_fastlane_ is the easiest way to automate beta deployments and releases for your iOS and Android apps. To learn more, check out [fastlane.tools](https://fastlane.tools).
