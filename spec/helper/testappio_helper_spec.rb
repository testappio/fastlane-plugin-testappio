describe Fastlane::Helper::TestappioHelper do
  describe ".handle_error" do
    it "does nothing when errors array is empty" do
      expect { described_class.handle_error([]) }.not_to raise_error
    end

    it "skips nil entries" do
      expect { described_class.handle_error([nil, nil]) }.not_to raise_error
    end

    it "does not raise when stderr lines do not match /Error/" do
      expect { described_class.handle_error(["Warning: deprecated flag", "info: starting"]) }
        .not_to raise_error
    end

    it "raises user_error when any stderr line matches /Error/" do
      expect { described_class.handle_error(["info: started", "Error: bad token"]) }
        .to raise_error(FastlaneCore::Interface::FastlaneError, /Error while calling ta-cli/)
    end

    it "raises when stderr contains both Error and warning lines (mixed)" do
      expect { described_class.handle_error(["warn: deprecated flag", "Error: auth failed", "info: cleanup"]) }
        .to raise_error(FastlaneCore::Interface::FastlaneError, /Error while calling ta-cli/)
    end

    it "includes the actual Error-line content in the raised message" do
      expect { described_class.handle_error(["Error: provisioning profile expired", "Error: deployment target invalid"]) }
        .to raise_error(FastlaneCore::Interface::FastlaneError) do |e|
          expect(e.message).to include("provisioning profile expired")
          expect(e.message).to include("deployment target invalid")
        end
    end
  end

  describe ".call_ta_cli verbose logging" do
    let(:command) do
      [
        "ta-cli", "publish",
        "--api_token=SECRET_TOKEN_xyz123",
        "--app_id=app-1",
        "--release=ios"
      ]
    end

    before do
      allow(FastlaneCore::Globals).to receive(:verbose?).and_return(true)
      wait_thr = instance_double(Process::Waiter, value: instance_double(Process::Status, success?: true))
      allow(Open3).to receive(:popen3).and_yield(StringIO.new, StringIO.new(""), StringIO.new(""), wait_thr)
    end

    it "does not leak the api_token to UI.command" do
      expect(FastlaneCore::UI).not_to receive(:command).with(/SECRET_TOKEN_xyz123/)
      allow(FastlaneCore::UI).to receive(:command)
      described_class.call_ta_cli(command)
    end

    it "displays a masked --api_token argument" do
      received = nil
      allow(FastlaneCore::UI).to receive(:command) { |arg| received = arg }
      described_class.call_ta_cli(command)
      expect(received.to_s).to match(/--api_token=\*+/)
    end
  end

  describe ".check_ta_cli" do
    it "returns true when ta-cli is already on PATH" do
      allow(described_class).to receive(:system).with("which ta-cli > /dev/null 2>&1").and_return(true)
      expect(described_class.check_ta_cli).to be true
    end

    it "installs and returns true when ta-cli is missing and install succeeds" do
      allow(described_class).to receive(:system).with("which ta-cli > /dev/null 2>&1").and_return(false)
      allow(described_class).to receive(:system).with(/curl -Ls.*install \| bash/).and_return(true)
      expect(described_class.check_ta_cli).to be true
    end

    it "returns false when ta-cli is missing and install fails" do
      allow(described_class).to receive(:system).with("which ta-cli > /dev/null 2>&1").and_return(false)
      allow(described_class).to receive(:system).with(/curl -Ls.*install \| bash/).and_return(false)
      expect(described_class.check_ta_cli).to be false
    end
  end

  describe ".check_update" do
    def stub_ta_cli_version(output)
      allow(described_class).to receive(:`).with("ta-cli version").and_return(output)
    end

    it "returns true when ta-cli is already up-to-date" do
      stub_ta_cli_version("ta-cli is up-to-date")
      expect(described_class.check_update(false)).to be true
    end

    it "raises user_error on breaking changes when self_update is false" do
      stub_ta_cli_version("breaking changes detected")
      expect { described_class.check_update(false) }
        .to raise_error(FastlaneCore::Interface::FastlaneError, /breaking changes/)
    end

    it "updates ta-cli when breaking changes detected and self_update is true" do
      # `ta-cli version` is called twice — once before the curl update (returns
      # "breaking changes") and once after (returns clean).
      call_count = 0
      allow(described_class).to receive(:`) do
        call_count += 1
        call_count == 1 ? "breaking changes detected" : "ok"
      end
      allow(Open3).to receive(:capture3).with(/curl -Ls.*install \| bash/)
                                        .and_return(["ta-cli successfully installed", "", instance_double(Process::Status, success?: true)])
      expect(described_class.check_update(true)).to be true
    end

    it "returns true with warning when new-version available and self_update is false" do
      stub_ta_cli_version("New version available")
      expect(described_class.check_update(false)).to be true
    end

    it "updates and returns true when new-version available and self_update is true" do
      call_count = 0
      allow(described_class).to receive(:`) do
        call_count += 1
        call_count == 1 ? "New version available" : "ok"
      end
      allow(Open3).to receive(:capture3).with(/curl -Ls.*install \| bash/)
                                        .and_return(["ta-cli has been updated", "", instance_double(Process::Status, success?: true)])
      expect(described_class.check_update(true)).to be true
    end

    it "raises when post-update version is still outdated" do
      call_count = 0
      allow(described_class).to receive(:`) do
        call_count += 1
        call_count == 1 ? "New version available" : "Update necessary due to breaking changes"
      end
      allow(Open3).to receive(:capture3).with(/curl -Ls.*install \| bash/)
                                        .and_return(["ta-cli has been updated", "", instance_double(Process::Status, success?: true)])
      expect { described_class.check_update(true) }
        .to raise_error(FastlaneCore::Interface::FastlaneError, /still outdated/)
    end

    it "raises when curl update output is unexpected" do
      stub_ta_cli_version("New version available")
      allow(Open3).to receive(:capture3).with(/curl -Ls.*install \| bash/)
                                        .and_return(["curl: connection refused", "", instance_double(Process::Status, success?: false)])
      expect { described_class.check_update(true) }
        .to raise_error(FastlaneCore::Interface::FastlaneError, /Error updating ta-cli/)
    end
  end

  describe ".call_ta_cli execution" do
    let(:base_command) { ["ta-cli", "publish", "--api_token=t", "--app_id=a", "--release=ios"] }

    it "streams stdout lines to UI.message (stripped) and returns the original raw stdout" do
      stub_popen3(stdout: "line one\nline two\n", success: true)
      messages = []
      allow(FastlaneCore::UI).to receive(:message) { |m| messages << m }

      result = described_class.call_ta_cli(base_command)

      expect(messages).to include("line one", "line two")
      # Original raw stdout is preserved (lines include their newlines).
      expect(result).to eq("line one\nline two\n")
    end

    it "calls handle_error when ta-cli exits non-zero with /Error/ stderr" do
      stub_popen3(stdout: "", stderr: "Error: bad token\n", success: false)
      expect { described_class.call_ta_cli(base_command) }
        .to raise_error(FastlaneCore::Interface::FastlaneError, /Error while calling ta-cli/)
    end

    it "does not call handle_error on successful exit even with non-Error stderr" do
      stub_popen3(stdout: "ok\n", stderr: "warn: deprecated\n", success: true)
      expect { described_class.call_ta_cli(base_command) }.not_to raise_error
    end

    it "does NOT raise on non-zero exit when stderr contains only warnings (no /Error/)" do
      stub_popen3(stdout: "", stderr: "warn: deprecated flag\n", success: false)
      expect { described_class.call_ta_cli(base_command) }.not_to raise_error
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
      expect(received_args).to eq(command)
    end
  end
end
