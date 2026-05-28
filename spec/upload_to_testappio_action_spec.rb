describe Fastlane::Actions::UploadToTestappioAction do
  let(:ipa_path) do
    f = Tempfile.create(["build", ".ipa"])
    f.close
    f.path
  end

  let(:apk_path) do
    f = Tempfile.create(["build", ".apk"])
    f.close
    f.path
  end

  before do
    allow(Fastlane::Helper::TestappioHelper).to receive(:check_ta_cli).and_return(true)
    allow(Fastlane::Helper::TestappioHelper).to receive(:check_update).and_return(true)
    allow(Fastlane::Helper::TestappioHelper).to receive(:call_ta_cli).and_return("ok")
  end

  describe ".run happy paths" do
    it "uploads for release=both with both apk and ipa" do
      received = nil
      allow(Fastlane::Helper::TestappioHelper).to receive(:call_ta_cli) { |cmd|
        received = cmd
        "ok"
      }

      Fastlane::FastFile.new.parse(<<~RUBY).runner.execute(:test)
        lane :test do
          upload_to_testappio(
            api_token: "tok",
            app_id: "app-1",
            release: "both",
            apk_file: "#{apk_path}",
            ipa_file: "#{ipa_path}"
          )
        end
      RUBY

      expect(received).to include("--api_token=tok", "--app_id=app-1", "--release=both")
      expect(received).to include("--apk=#{apk_path}", "--ipa=#{ipa_path}")
      expect(received.find { |a| a.start_with?("--source=") }).to eq("--source=Fastlane")
      expect(received.find { |a| a.start_with?("--source_version=") })
        .to eq("--source_version=#{Fastlane::Testappio::VERSION}")
    end

    it "uploads for release=ios and omits --apk" do
      received = nil
      allow(Fastlane::Helper::TestappioHelper).to receive(:call_ta_cli) { |cmd|
        received = cmd
        "ok"
      }

      Fastlane::FastFile.new.parse(<<~RUBY).runner.execute(:test)
        lane :test do
          upload_to_testappio(api_token: "tok", app_id: "a", release: "ios", ipa_file: "#{ipa_path}")
        end
      RUBY

      expect(received).to include("--release=ios", "--ipa=#{ipa_path}")
      expect(received.none? { |a| a.start_with?("--apk=") }).to be true
    end

    it "uploads for release=android and omits --ipa" do
      received = nil
      allow(Fastlane::Helper::TestappioHelper).to receive(:call_ta_cli) { |cmd|
        received = cmd
        "ok"
      }

      Fastlane::FastFile.new.parse(<<~RUBY).runner.execute(:test)
        lane :test do
          upload_to_testappio(api_token: "tok", app_id: "a", release: "android", apk_file: "#{apk_path}")
        end
      RUBY

      expect(received).to include("--release=android", "--apk=#{apk_path}")
      expect(received.none? { |a| a.start_with?("--ipa=") }).to be true
    end
  end

  describe ".run early returns" do
    it "returns without calling ta-cli when check_ta_cli is false" do
      allow(Fastlane::Helper::TestappioHelper).to receive(:check_ta_cli).and_return(false)
      expect(Fastlane::Helper::TestappioHelper).not_to receive(:call_ta_cli)

      Fastlane::FastFile.new.parse(<<~RUBY).runner.execute(:test)
        lane :test do
          upload_to_testappio(api_token: "tok", app_id: "a", release: "ios", ipa_file: "#{ipa_path}")
        end
      RUBY
    end

    it "returns without calling ta-cli when check_update is false" do
      allow(Fastlane::Helper::TestappioHelper).to receive(:check_update).and_return(false)
      expect(Fastlane::Helper::TestappioHelper).not_to receive(:call_ta_cli)

      Fastlane::FastFile.new.parse(<<~RUBY).runner.execute(:test)
        lane :test do
          upload_to_testappio(api_token: "tok", app_id: "a", release: "ios", ipa_file: "#{ipa_path}")
        end
      RUBY
    end
  end

  describe "input validation" do
    it "raises when api_token is empty (verify_block)" do
      expect do
        Fastlane::FastFile.new.parse(<<~RUBY).runner.execute(:test)
          lane :test do
            upload_to_testappio(api_token: "", app_id: "a", release: "ios", ipa_file: "#{ipa_path}")
          end
        RUBY
      end.to raise_error(FastlaneCore::Interface::FastlaneError, /No API token provided/)
    end

    it "raises when api_token is nil (verify_block)" do
      expect do
        Fastlane::FastFile.new.parse(<<~RUBY).runner.execute(:test)
          lane :test do
            upload_to_testappio(api_token: nil, app_id: "a", release: "ios", ipa_file: "#{ipa_path}")
          end
        RUBY
      end.to raise_error(FastlaneCore::Interface::FastlaneError, /No API token provided/)
    end

    it "raises when ipa_file does not exist on release=ios" do
      expect do
        Fastlane::FastFile.new.parse(<<~RUBY).runner.execute(:test)
          lane :test do
            upload_to_testappio(api_token: "t", app_id: "a", release: "ios", ipa_file: "/tmp/nope-#{SecureRandom.hex}.ipa")
          end
        RUBY
      end.to raise_error(FastlaneCore::Interface::FastlaneError, /No file found/)
    end

    it "raises when extension is not .apk or .ipa" do
      Tempfile.create(["build", ".zip"]) do |f|
        expect do
          Fastlane::FastFile.new.parse(<<~RUBY).runner.execute(:test)
            lane :test do
              upload_to_testappio(api_token: "t", app_id: "a", release: "ios", ipa_file: "#{f.path}")
            end
          RUBY
        end.to raise_error(FastlaneCore::Interface::FastlaneError, /file_path is invalid/)
      end
    end
  end

  describe "metadata" do
    it "exposes return_value without raising NameError" do
      expect { described_class.return_value }.not_to raise_error
    end

    it "return_value returns nil" do
      expect(described_class.return_value).to be_nil
    end

    it "exposes a non-empty description" do
      expect(described_class.description).to be_a(String).and(satisfy { |s| !s.empty? })
    end

    it "exposes a non-empty details string" do
      expect(described_class.details).to be_a(String).and(satisfy { |s| !s.empty? })
    end

    it "exposes authors as TestApp.io" do
      expect(described_class.authors).to eq(["TestApp.io"])
    end

    it "output returns nil" do
      expect(described_class.output).to be_nil
    end
  end

  describe ".is_supported?" do
    it "supports :ios" do
      expect(described_class.is_supported?(:ios)).to be true
    end

    it "supports :android" do
      expect(described_class.is_supported?(:android)).to be true
    end

    it "does not support :mac" do
      expect(described_class.is_supported?(:mac)).to be false
    end
  end

  describe ".default_file_path" do
    it "returns IPA_OUTPUT_PATH when platform is :ios" do
      Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::PLATFORM_NAME] = :ios
      Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::IPA_OUTPUT_PATH] = "/tmp/x.ipa"
      expect(described_class.default_file_path).to eq("/tmp/x.ipa")
    end

    it "returns GRADLE_APK_OUTPUT_PATH otherwise" do
      Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::PLATFORM_NAME] = :android
      Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::GRADLE_APK_OUTPUT_PATH] = "/tmp/x.apk"
      expect(described_class.default_file_path).to eq("/tmp/x.apk")
    end
  end

  describe ".validate_file_path" do
    it "returns silently when file_path is nil" do
      expect { described_class.validate_file_path(nil) }.not_to raise_error
    end

    it "raises user_error when file does not exist" do
      expect { described_class.validate_file_path("/tmp/does-not-exist-#{SecureRandom.hex}.apk") }
        .to raise_error(FastlaneCore::Interface::FastlaneError, /No file found/)
    end

    it "raises user_error when extension is not apk or ipa" do
      Tempfile.create(["build", ".zip"]) do |f|
        expect { described_class.validate_file_path(f.path) }
          .to raise_error(FastlaneCore::Interface::FastlaneError, /file_path is invalid/)
      end
    end
  end

  describe ".available_options" do
    it "exposes 10 ConfigItems" do
      expect(described_class.available_options.size).to eq(10)
    end

    it "exposes the expected parameter keys (public API)" do
      keys = described_class.available_options.map(&:key)
      expect(keys).to eq(%i[
                           api_token app_id release apk_file ipa_file
                           release_notes git_release_notes git_commit_id notify self_update
                         ])
    end

    it "exposes the expected env_name for each ConfigItem (public API)" do
      env_names = described_class.available_options.map(&:env_name)
      expect(env_names).to include(
        "TESTAPPIO_API_TOKEN", "TESTAPPIO_APP_ID", "TESTAPPIO_RELEASE",
        "TESTAPPIO_ANDROID_PATH", "TESTAPPIO_IOS_PATH",
        "TESTAPPIO_RELEASE_NOTES", "TESTAPPIO_GIT_RELEASE_NOTES",
        "TESTAPPIO_GIT_COMMIT_ID", "TESTAPPIO_NOTIFY", "TESTAPPIO_SELF_UPDATE"
      )
    end
  end
end
