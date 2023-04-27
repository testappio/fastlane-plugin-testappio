module Fastlane
  module Actions
    class UploadToTestappioAction < Action
      SUPPORTED_FILE_EXTENSIONS = ["apk", "ipa"]

      def self.run(params)

        # Check if `ta_cli` exists, install it if not
        unless Helper::TestappioHelper.check_ta_cli
          UI.error("Error detecting ta-cli")
          return
        end

        api_token = params[:api_token]
        app_id = params[:app_id]
        apk_file = params[:apk_file]
        ipa_file = params[:ipa_file]
        release = params[:release]
        release_notes = params[:release_notes]
        git_release_notes = params[:git_release_notes]
        git_commit_id = params[:git_commit_id]
        notify = params[:notify]
        self_update = params[:self_update]

        # Check if ta-cli needs to be updated
        unless Helper::TestappioHelper.check_update(self_update)
          UI.error("Error updating ta-cli")
          return
        end

        validate_file_path(apk_file) unless release == "ios"
        validate_file_path(ipa_file) unless release == "android"

        command = ["ta-cli", "version",
                   "--api_token=#{api_token}",
                   "--app_id=#{app_id}",
                   "--release=#{release}"]

        command.push("--apk=#{apk_file}") unless release == "ios"
        command.push("--ipa=#{ipa_file}") unless release == "android"

        command += ["--release_notes=#{release_notes}",
                    "--git_release_notes=#{git_release_notes}",
                    "--git_commit_id=#{git_commit_id}",
                    "--notify=#{notify}",
                    "--source=Fastlane"]

        UI.message("Uploading to TestApp.io")
        Helper::TestappioHelper.call_ta_cli(command)
        UI.success("Successfully uploaded to TestApp.io!")
      end

      def self.validate_file_path(file_path)
        UI.user_error!("No file found at '#{file_path}'.") unless File.exist?(file_path)

        file_ext = File.extname(file_path).delete('.')
        unless SUPPORTED_FILE_EXTENSIONS.include?(file_ext)
          UI.user_error!("file_path is invalid, only files with extensions #{SUPPORTED_FILE_EXTENSIONS} are allowed to be uploaded.")
        end
      end

      def self.description
        "Uploading ipa/apk packages to TestApp.io for testing."
      end

      def self.default_file_path
        platform = Actions.lane_context[Actions::SharedValues::PLATFORM_NAME]
        if platform == :ios
          # Shared value for ipa path if it was generated by gym https://docs.fastlane.tools/actions/gym/.
          return Actions.lane_context[Actions::SharedValues::IPA_OUTPUT_PATH]
        else
          # Shared value for apk if it was generated by gradle.
          return Actions.lane_context[Actions::SharedValues::GRADLE_APK_OUTPUT_PATH]
        end
      end

      def self.details
        "This Fastlane plugin uploads your Android (APK) and iOS (IPA) package to TestApp.io and notify your team members about the new releases if you enable it."
      end

      def self.available_options
        # Define all options your action supports.

        # Below a few examples
        [
          FastlaneCore::ConfigItem.new(key: :api_token,
                                       env_name: "TESTAPPIO_API_TOKEN",
                                       description: "You can get it from https://portal.testapp.io/settings/api-credentials",
                                       verify_block: proc do |value|
                                         UI.user_error!("No API token provided. You can get it from https://portal.testapp.io/settings/api-credentials") unless value && !value.empty?
                                       end),
          FastlaneCore::ConfigItem.new(key: :app_id,
                                       env_name: "TESTAPPIO_APP_ID",
                                       description: "You can get it from your app page in https://portal.testapp.io/apps?action=select-for-integrations",
                                       is_string: false),
          FastlaneCore::ConfigItem.new(key: :release,
                                       env_name: "TESTAPPIO_RELEASE",
                                       description: "It can be either both or android or ios",
                                       is_string: true,
                                      default_value: Actions.lane_context[Actions::SharedValues::PLATFORM_NAME]),
          FastlaneCore::ConfigItem.new(key: :apk_file,
                                      env_name: "TESTAPPIO_ANDROID_PATH",
                                      description: "Full path to the Android .apk file",
                                      optional: true,
                                      is_string: true,
                                      default_value: default_file_path),
          FastlaneCore::ConfigItem.new(key: :ipa_file,
                                      env_name: "TESTAPPIO_IOS_PATH",
                                      description: "Full path to the iOS .ipa file",
                                      optional: true,
                                      is_string: true,
                                      default_value: default_file_path),
          FastlaneCore::ConfigItem.new(key: :release_notes,
                                      env_name: "TESTAPPIO_RELEASE_NOTES",
                                      description: "Manually add the release notes to be displayed for the testers",
                                      optional: true,
                                      is_string: true),
          FastlaneCore::ConfigItem.new(key: :git_release_notes,
                                      env_name: "TESTAPPIO_GIT_RELEASE_NOTES",
                                      description: "Collect release notes from the latest git commit message to be displayed for the testers: true or false",
                                      optional: true,
                                      is_string: false,
                                      default_value: true),
          FastlaneCore::ConfigItem.new(key: :git_commit_id,
                                      env_name: "TESTAPPIO_GIT_COMMIT_ID",
                                      description: "Include the last commit ID in the release notes (works with both release notes option): true or false",
                                      optional: true,
                                      is_string: false,
                                      default_value: false),
          FastlaneCore::ConfigItem.new(key: :notify,
                                      env_name: "TESTAPPIO_NOTIFY",
                                      description: "Send notificaitons to your team members about this release: true or false",
                                      optional: true,
                                      is_string: false,
                                      default_value: false),
          FastlaneCore::ConfigItem.new(key: :self_update,
                                      env_name: "TESTAPPIO_SELF_UPDATE",
                                      description: "Automatically update ta-cli if a new version is available or required: true or false",
                                      optional: true,
                                      is_string: false,
                                      default_value: true)
        ]
      end

      def self.output
        nil
      end

      def self.return_value
        nill
      end

      def self.authors
        ["TestApp.io"]
      end

      def self.is_supported?(platform)
        [:ios, :android].include?(platform)
      end
    end
  end
end
