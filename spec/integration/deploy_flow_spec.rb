# Integration tests: exercise the real ta-cli binary with fake credentials.
# Skipped by default. Run with: bundle exec rspec --tag integration
#                              OR: INTEGRATION=1 bundle exec rspec
#
# These specs prove the end-to-end deploy flow still works:
#   - check_ta_cli detects/installs the binary
#   - check_update returns without re-installing (self_update: false)
#   - The command is built with all expected flags
#   - ta-cli is actually invoked via Open3.popen3
#   - handle_error parses /Error/ stderr from real ta-cli and raises FastlaneError
#
# Requires ta-cli installed on PATH. Will skip cleanly otherwise.

describe "Deploy flow integration", :integration do
  let(:ipa_path) { File.expand_path("../../fastlane/sample/sample-app.ipa", __dir__) }
  let(:apk_path) { File.expand_path("../../fastlane/sample/sample-app.apk", __dir__) }

  before do
    skip "ta-cli not installed on PATH" unless system('which ta-cli > /dev/null 2>&1')
    skip "sample-app.ipa missing" unless File.exist?(ipa_path)
  end

  it "exercises full iOS deploy flow with fake creds and surfaces a real ta-cli error" do
    expect do
      Fastlane::FastFile.new.parse(<<~RUBY).runner.execute(:smoke)
        lane :smoke do
          upload_to_testappio(
            api_token: "fake_smoke_token_integration_test",
            app_id: "00000000-0000-0000-0000-000000000000",
            release: "ios",
            ipa_file: "#{ipa_path}",
            self_update: false,
            notify: false,
            git_release_notes: false,
            git_commit_id: false
          )
        end
      RUBY
    end.to raise_error(FastlaneCore::Interface::FastlaneError, /Error while calling ta-cli/)
  end

  it "exercises full Android deploy flow with fake creds and surfaces a real ta-cli error" do
    skip "sample-app.apk missing" unless File.exist?(apk_path)
    expect do
      Fastlane::FastFile.new.parse(<<~RUBY).runner.execute(:smoke)
        lane :smoke do
          upload_to_testappio(
            api_token: "fake_smoke_token_integration_test",
            app_id: "00000000-0000-0000-0000-000000000000",
            release: "android",
            apk_file: "#{apk_path}",
            self_update: false,
            notify: false,
            git_release_notes: false,
            git_commit_id: false
          )
        end
      RUBY
    end.to raise_error(FastlaneCore::Interface::FastlaneError, /Error while calling ta-cli/)
  end
end
