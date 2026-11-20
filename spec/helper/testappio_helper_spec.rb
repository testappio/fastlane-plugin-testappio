describe Fastlane::Helper::TestappioHelper do
  let(:install_command) { ["bash", "-o", "pipefail", "-c", /curl -fLs.*install \| bash/] }
  let(:credential_free_env) { { "TESTAPPIO_API_TOKEN" => nil, "API_TOKEN" => nil } }

  describe ".call_ta_cli verbose logging" do
    let(:token) { SecureRandom.hex(16) }
    let(:command) do
      [
        "ta-cli", "publish",
        "--release_notes=notes mentioning #{token}",
        "--app_id=app-1",
        "--release=ios"
      ]
    end

    before do
      allow(FastlaneCore::Globals).to receive(:verbose?).and_return(true)
      wait_thr = instance_double(Process::Waiter, value: instance_double(Process::Status, success?: true))
      allow(Open3).to receive(:popen3).and_yield(StringIO.new, StringIO.new(""), StringIO.new(""), wait_thr)
    end

    it "redacts a token that appears inside another logged argument" do
      received = nil
      allow(FastlaneCore::UI).to receive(:command) { |arg| received = arg }
      described_class.call_ta_cli(command, token)
      expect(received.include?(token)).to be false
      expect(received).to include("--release_notes=notes mentioning ********")
    end
  end

  describe ".check_ta_cli" do
    it "returns true when ta-cli is already on PATH" do
      allow(FastlaneCore::Helper).to receive(:which).with("ta-cli").and_return("/usr/local/bin/ta-cli")
      expect(described_class.check_ta_cli).to be true
    end

    it "installs and returns true when ta-cli is missing and install succeeds" do
      allow(FastlaneCore::Helper).to receive(:which).with("ta-cli").and_return(nil)
      allow(Open3).to receive(:capture3).with(credential_free_env, *install_command)
                                        .and_return(["ta-cli successfully installed", "", command_status(0)])
      expect(described_class.check_ta_cli).to be true
    end

    it "raises when ta-cli is missing and install fails" do
      allow(FastlaneCore::Helper).to receive(:which).with("ta-cli").and_return(nil)
      allow(Open3).to receive(:capture3).with(credential_free_env, *install_command).and_return(["", "", command_status(22)])
      expect { described_class.check_ta_cli }
        .to raise_error(FastlaneCore::Interface::FastlaneError, /Error installing ta-cli/)
    end

    it "withholds child credentials and redacts diagnostics from a failed initial install" do
      token = SecureRandom.hex(16)
      credentials_removed = false
      allow(FastlaneCore::Helper).to receive(:which).with("ta-cli").and_return(nil)
      allow(Open3).to receive(:capture3) do |environment, *|
        credentials_removed = %w[TESTAPPIO_API_TOKEN API_TOKEN].all? { |name| environment.key?(name) && environment[name].nil? }
        ["setup #{token}", "download failed #{token}", command_status(19)]
      end
      messages = []
      allow(FastlaneCore::UI).to receive(:verbose) { |message| messages << message }

      expect { described_class.check_ta_cli(token) }.to raise_error(FastlaneCore::Interface::FastlaneError) do |error|
        expect(error.message.include?(token)).to be false
        expect(error.message).to include("exit status 19", "setup ********", "download failed ********")
      end
      expect(credentials_removed).to be true
      expect(messages.any? { |message| message.include?(token) }).to be false
    end
  end

  describe ".check_update" do
    let(:required_update_notice) { "Update necessary due to breaking changes" }

    def stub_ta_cli_version(*responses)
      allow(Open3).to receive(:capture3).with(credential_free_env, "ta-cli", "version").and_return(*responses)
    end

    it "returns true when ta-cli is already up-to-date" do
      stub_ta_cli_version(["ta-cli is up-to-date", "", command_status(0)])
      expect(described_class.check_update(false)).to be true
    end

    it "raises user_error on breaking changes when self_update is false" do
      stub_ta_cli_version([required_update_notice, "", command_status(1)])
      expect { described_class.check_update(false) }
        .to raise_error(FastlaneCore::Interface::FastlaneError, /update ta-cli manually/)
    end

    it "updates ta-cli when breaking changes detected and self_update is true" do
      stub_ta_cli_version([required_update_notice, "", command_status(0)], ["ok", "", command_status(0)])
      expect(Open3).to receive(:capture3).with(credential_free_env, *install_command)
                                         .and_return(["ta-cli successfully installed", "", command_status(0)])
      expect(described_class.check_update(true)).to be true
    end

    it "returns true with warning when new-version available and self_update is false" do
      stub_ta_cli_version(["New version available", "", command_status(0)])
      expect(described_class.check_update(false)).to be true
    end

    it "updates and returns true when new-version available and self_update is true" do
      stub_ta_cli_version(["New version available", "", command_status(0)], ["ok", "", command_status(0)])
      allow(Open3).to receive(:capture3).with(credential_free_env, *install_command)
                                        .and_return(["ta-cli has been updated", "", command_status(0)])
      expect(described_class.check_update(true)).to be true
    end

    it "raises when post-update version is still outdated" do
      stub_ta_cli_version(["New version available", "", command_status(0)], [required_update_notice, "", command_status(0)])
      allow(Open3).to receive(:capture3).with(credential_free_env, *install_command)
                                        .and_return(["ta-cli has been updated", "", command_status(0)])
      expect { described_class.check_update(true) }
        .to raise_error(FastlaneCore::Interface::FastlaneError, /still outdated/)
    end

    it "reports still outdated when the post-update version exits nonzero with the forced notice" do
      stub_ta_cli_version(["New version available", "", command_status(0)], [required_update_notice, "", command_status(1)])
      allow(Open3).to receive(:capture3).with(credential_free_env, *install_command)
                                        .and_return(["ta-cli has been updated", "", command_status(0)])
      expect { described_class.check_update(true) }
        .to raise_error(FastlaneCore::Interface::FastlaneError, /still outdated/)
    end

    it "raises when curl update output is unexpected" do
      stub_ta_cli_version(["New version available", "", command_status(0)])
      allow(Open3).to receive(:capture3).with(credential_free_env, *install_command)
                                        .and_return(["unexpected installer output", "", command_status(0)])
      expect { described_class.check_update(true) }
        .to raise_error(FastlaneCore::Interface::FastlaneError, /Error updating ta-cli/)
    end

    it "fails a non-zero update even when its output includes a success message" do
      stub_ta_cli_version(["New version available", "", command_status(0)], ["ok", "", command_status(0)])
      allow(Open3).to receive(:capture3).with(credential_free_env, *install_command)
                                        .and_return(["ta-cli has been updated", "", command_status(22)])
      expect { described_class.check_update(true) }
        .to raise_error(FastlaneCore::Interface::FastlaneError, /Error updating ta-cli/)
    end

    it "fails an ordinary version check with non-zero status and empty output" do
      stub_ta_cli_version(["", "", command_status(23)])
      expect { described_class.check_update(false) }
        .to raise_error(FastlaneCore::Interface::FastlaneError, /Error checking ta-cli version.*exit status 23/)
    end

    ["stdout", "stderr"].each do |stream|
      it "updates and re-checks after a nonzero forced-update notice on #{stream}" do
        notice = "Update necessary"
        first = stream == "stdout" ? [notice, ""] : ["", notice]
        expect(Open3).to receive(:capture3).with(credential_free_env, "ta-cli", "version")
                                           .ordered.and_return([*first, command_status(1)])
        expect(Open3).to receive(:capture3).with(credential_free_env, *install_command)
                                           .ordered.and_return(["ta-cli has been updated", "", command_status(0)])
        expect(Open3).to receive(:capture3).with(credential_free_env, "ta-cli", "version")
                                           .ordered.and_return(["ok", "", command_status(0)])
        expect(described_class.check_update(true)).to be true
      end
    end

    it "fails a version check terminated by a signal even after printing a forced update notice" do
      status = instance_double(Process::Status, success?: nil, signaled?: true, exitstatus: nil, termsig: 9)
      stub_ta_cli_version([required_update_notice, "", status])
      expect { described_class.check_update(true) }
        .to raise_error(FastlaneCore::Interface::FastlaneError, /Error checking ta-cli version.*signal 9/)
    end

    it "withholds credentials and redacts version check and update diagnostics" do
      token = SecureRandom.hex(16)
      credential_status = []
      allow(Open3).to receive(:capture3) do |environment, command, *|
        credential_status << %w[TESTAPPIO_API_TOKEN API_TOKEN].all? { |name| environment.key?(name) && environment[name].nil? }
        if command == "ta-cli"
          ["New version available #{token}", "checking #{token}", command_status(0)]
        else
          ["starting #{token}", "update failed #{token}", command_status(17)]
        end
      end
      messages = []
      allow(FastlaneCore::UI).to receive(:verbose) { |message| messages << message }

      expect { described_class.check_update(true, token) }.to raise_error(FastlaneCore::Interface::FastlaneError) do |error|
        expect(error.message.include?(token)).to be false
        expect(error.message).to include("exit status 17", "starting ********", "update failed ********")
      end
      expect(credential_status).to eq([true, true])
      expect(messages.any? { |message| message.include?(token) }).to be false
      expect(messages).to include("New version available ********", "checking ********")
    end

    it "fails when the version check after a successful update exits unsuccessfully" do
      stub_ta_cli_version(["New version available", "", command_status(0)], ["", "version check failed", command_status(29)])
      allow(Open3).to receive(:capture3).with(credential_free_env, *install_command)
                                        .and_return(["ta-cli has been updated", "", command_status(0)])
      expect { described_class.check_update(true) }
        .to raise_error(FastlaneCore::Interface::FastlaneError, /Error checking ta-cli version.*exit status 29.*version check failed/)
    end
  end

  describe ".call_ta_cli execution" do
    let(:base_command) { ["ta-cli", "publish", "--app_id=a", "--release=ios"] }

    it "streams stdout lines to UI.message (stripped) and returns the original raw stdout" do
      stub_popen3(stdout: "line one\n\nline two\n", success: true)
      messages = []
      allow(FastlaneCore::UI).to receive(:message) { |m| messages << m }

      result = described_class.call_ta_cli(base_command)

      expect(messages).to include("line one", "line two")
      expect(messages).not_to include("")
      # Original raw stdout is preserved (lines include their newlines).
      expect(result).to eq("line one\n\nline two\n")
    end

    it "includes each nonempty stderr line in a failure" do
      stub_popen3(stdout: "", stderr: "Error: bad token\n\nWarning: deprecated flag\n", success: false)
      expect { described_class.call_ta_cli(base_command) }
        .to raise_error(FastlaneCore::Interface::FastlaneError, /Error while calling ta-cli.*Error: bad token \| Warning: deprecated flag/)
    end

    it "does not fail a successful exit when stderr contains a warning" do
      stub_popen3(stdout: "ok\n", stderr: "Warning: deprecated flag\n", success: true)
      expect { described_class.call_ta_cli(base_command) }.not_to raise_error
    end

    it "raises on non-zero exit with a warning-only diagnostic" do
      command = [RbConfig.ruby, "-e", 'warn "deprecated flag"; exit 7']
      expect { described_class.call_ta_cli(command) }
        .to raise_error(FastlaneCore::Interface::FastlaneError, /exit status 7.*deprecated flag/)
    end

    it "raises on non-zero exit with empty stderr" do
      command = [RbConfig.ruby, "-e", "exit 23"]
      expect { described_class.call_ta_cli(command) }
        .to raise_error(FastlaneCore::Interface::FastlaneError, /exit status 23/)
    end

    it "raises when the child is terminated by a signal" do
      command = [RbConfig.ruby, "-e", 'Process.kill("KILL", Process.pid)']
      expect { described_class.call_ta_cli(command) }
        .to raise_error(FastlaneCore::Interface::FastlaneError, /signal #{Signal.list.fetch('KILL')}/)
    end

    it "sets both credential names only in the publish child and keeps the token out of argv" do
      names = %w[API_TOKEN TESTAPPIO_API_TOKEN]
      parent = ENV.values_at(*names)
      token = SecureRandom.hex(16)
      child = 'a, b = ENV.values_at("API_TOKEN", "TESTAPPIO_API_TOKEN"); abort "missing credentials" unless a && a == b && !ARGV.include?(a)'
      described_class.call_ta_cli([RbConfig.ruby, "-e", child], token)
      expect(ENV.values_at(*names) == parent).to be true
    end

    it "redacts the child token from stdout and failure diagnostics" do
      token = SecureRandom.hex(16)
      child_code = 'token = ENV.fetch("TESTAPPIO_API_TOKEN"); puts "received " + token; warn "stderr " + token; exit 7'
      messages = []
      allow(FastlaneCore::UI).to receive(:message) { |message| messages << message }

      expect do
        described_class.call_ta_cli([RbConfig.ruby, "-e", child_code], token)
      end.to raise_error(FastlaneCore::Interface::FastlaneError) do |error|
        expect(error.message.include?(token)).to be false
        expect(error.message).to include("stderr ********")
      end
      expect(messages.any? { |message| message.include?(token) }).to be false
      expect(messages).to include("received ********")
    end

    it "passes the command array to Open3.popen3 without shell interpretation" do
      received_args = nil
      allow(Open3).to receive(:popen3) do |*args, &blk|
        received_args = args
        wait_thr = instance_double(Process::Waiter, value: instance_double(Process::Status, success?: true))
        blk.call(StringIO.new, StringIO.new(""), StringIO.new(""), wait_thr)
      end

      command = ["ta-cli", "publish", "--release_notes=has spaces & quotes"]
      described_class.call_ta_cli(command)

      # Array form: each element passed as a separate positional arg to popen3.
      # No shell, no escaping needed — special chars survive as literal bytes.
      expect(received_args.drop(1)).to eq(command)
    end
  end
end
