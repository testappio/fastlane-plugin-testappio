# [<img src="https://assets.testapp.io/logo/blue.svg" alt="TestApp.io"/>](https://testapp.io/) Fastlane Plugin

> BETA mode. Your feedback is highly appreciated.

A Fastlane plugin to upload both Android & iOS apps to TestApp.io to notify everyone for testing and feedback.

[![fastlane Plugin Badge](https://rawcdn.githack.com/fastlane/fastlane/master/fastlane/assets/plugin-badge.svg)](https://rubygems.org/gems/fastlane-plugin-testappio) [![Gem Version](https://badge.fury.io/rb/fastlane-plugin-testappio.svg)](https://badge.fury.io/rb/fastlane-plugin-testappio)

## Getting started

This project is a [_Fastlane_](https://github.com/fastlane/fastlane) plugin. To get started with `fastlane-plugin-testappio`, add it to your project by running:

```bash
fastlane add_plugin testappio
```

## Configuration

_More info here: [https://help.testapp.io/ta-cli](https://help.testapp.io/ta-cli/)_

| Key               | Description                                                                                                                          | Env Var(s)                  | Default |
| ----------------- | ------------------------------------------------------------------------------------------------------------------------------------ | --------------------------- | ------- |
| api_token         | You can get it from https://portal.testapp.io/settings/api-credentials                                                               | TESTAPPIO_API_TOKEN         |         |
| app_id            | You can get it from your app page at [https://portal.testapp.io/apps](https://portal.testapp.io/apps?action=select-for-integrations) | TESTAPPIO_APP_ID            |         |
| release           | It can be either both or Android or iOS                                                                                              | TESTAPPIO_RELEASE           |         |
| apk_file          | Path to the Android APK file                                                                                                         | TESTAPPIO_ANDROID_PATH      |         |
| ipa_file          | Path to the iOS IPA file                                                                                                             | TESTAPPIO_IOS_PATH          |         |
| release_notes     | Manually add the release notes to be displayed for the testers                                                                       | TESTAPPIO_RELEASE_NOTES     |         |
| git_release_notes | Collect release notes from the latest git commit message to be displayed for the testers: true or false                              | TESTAPPIO_GIT_RELEASE_NOTES | true    |
| git_commit_id     | Include the last commit ID in the release notes (works with both release notes options): true or false                               | TESTAPPIO_GIT_COMMIT_ID     | false   |
| notify            | Send notifications to your team members about this release: true or false                                                            | TESTAPPIO_NOTIFY            | false   |

## TestApp.io actions

Actions provided by the CLI: [ta-cli](https://help.testapp.io/ta-cli/)

Check out the [example Fastfile](https://github.com/testappio/fastlane-plugin-testappio/blob/main/fastlane/Fastfile) to see how to use this plugin. Try it by cloning the repo, running `fastlane install_plugins` and `bundle exec fastlane test`.

To upload after the Fastlane `gym` action:

##### iOS

```ruby
  lane :beta do

    increment_build_number
    match(type: "adhoc")
    gym(export_method: "ad-hoc")

    upload_to_testappio(
      api_token: "Your API Token",
      app_id: "Your App ID",
      release_notes: "My release notes here...",
      git_release_notes: true,
      git_commit_id: false,
      notify: true
    )

    clean_build_artifacts #optional

  end
```

##### Android

```ruby
  lane :beta do

    increment_version_code #[Optional] fastlane add_plugin increment_version_code

    gradle(task: "clean assembleDebug") #or clean assembleRelease

    upload_to_testappio(
      api_token: "Your API Token", #You can get it from https://portal.testapp.io/settings/api-credentials
      app_id: "Your App ID", #You can get it from your app page in https://portal.testapp.io/apps
      release_notes: "My release notes here...",
      git_release_notes: true,
      git_commit_id: false,
      notify: true
    )

  end
```

## Troubleshooting

If you have trouble using plugins, check out the [Plugins Troubleshooting](https://docs.fastlane.tools/plugins/plugins-troubleshooting/) guide.

## Using _Fastlane_ plugins

Check out the [Plugins documentation](https://docs.fastlane.tools/plugins/create-plugin/) for more information about how the plugin system works.

## About _Fastlane_

_Fastlane_ is the easiest way to automate beta deployments and releases for iOS and Android apps. To learn more, check out [fastlane.tools](https://fastlane.tools).

---

## Feedback & Support

Developers built [TestApp.io](https://testapp.io) to solve the pain of app distribution for mobile app development teams.

Join our [Slack](https://join.slack.com/t/testappio/shared_invite/zt-pvpoj3l2-epGYwGTaV3~3~0f7udNWoA) channel for feedback and support.

Check out our [Help Center](https://help.testapp.io/) for more info and other integrations.

Happy releasing 🎉
