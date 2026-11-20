require 'fastlane_core/helper'
require 'fastlane_core/ui/ui'
require 'open3'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?(:UI)

  module Helper
    class TestappioHelper
      INSTALL_COMMAND = ["bash", "-o", "pipefail", "-c", "curl -fLs https://github.com/testappio/cli/releases/latest/download/install | bash"].freeze
      VERSION_COMMAND = ["ta-cli", "version"].freeze
      ENV_WITHOUT_TOKEN = { "TESTAPPIO_API_TOKEN" => nil, "API_TOKEN" => nil }.freeze
      REQUIRED_UPDATE_NOTICE = "Update necessary".freeze

      # Check if `ta_cli` exists, install it if not
      def self.check_ta_cli(api_token = nil)
        unless FastlaneCore::Helper.which("ta-cli")
          UI.error("ta-cli not found, installing")

          output, stderr, status = capture_cli(INSTALL_COMMAND, api_token)
          fail_command("Error installing ta-cli", status, output, stderr) unless status.success?
          UI.success("ta-cli installed")
        end

        return true
      end

      # Check if there is an update available for `ta_cli`, and install it if necessary
      def self.check_update(self_update, api_token = nil)
        version_output, version_error, version_status = capture_cli(VERSION_COMMAND, api_token)
        forced = [version_output, version_error].any? { |text| text.include?(REQUIRED_UPDATE_NOTICE) }
        unless version_status.success? || (forced && !version_status.signaled?)
          fail_command("Error checking ta-cli version", version_status, version_output, version_error)
        end

        if forced
          if self_update
            UI.message("Updating ta-cli due to breaking changes...")
          else
            # UI.user_error! raises FastlaneError; method never returns past this point.
            UI.user_error!("Update necessary due to breaking changes. Please update ta-cli manually or set self_update to true")
          end
        elsif version_output.include?("New version available")
          if self_update
            UI.message("Updating ta-cli...")
          else
            UI.important("New version available, but skipping update as self_update is set to false.")
            return true
          end
        else
          UI.success("ta-cli is already up-to-date")
          return true
        end

        update_output, update_error, update_status = capture_cli(INSTALL_COMMAND, api_token)
        fail_command("Error updating ta-cli", update_status, update_output, update_error) unless update_status.success?
        unless update_output.include?("ta-cli successfully installed") || update_output.include?("ta-cli has been updated")
          UI.user_error!("Error updating ta-cli: #{update_output.strip}")
        end

        version_output, version_error, version_status = capture_cli(VERSION_COMMAND, api_token)
        # A still-forced update exits nonzero, so check the notice before the exit status.
        if [version_output, version_error].any? { |text| text.include?(REQUIRED_UPDATE_NOTICE) } || version_output.include?("New version available")
          UI.user_error!("Error updating ta-cli: the version is still outdated")
        end
        fail_command("Error checking ta-cli version", version_status, version_output, version_error) unless version_status.success?

        UI.success("ta-cli has been updated successfully")
        true
      end

      # Stream stdout, keep the token in the child environment, and preserve
      # release notes and file paths as literal arguments.
      def self.call_ta_cli(command, api_token = nil)
        UI.message("Starting ta-cli...")
        if FastlaneCore::Globals.verbose?
          UI.verbose("ta-cli command:\n\n")
          UI.command(command.map { |argument| redact_token(argument, api_token) }.to_s)
          UI.verbose("\n\n")
        end

        out = []
        stderr_lines = []
        out_thread = nil
        err_thread = nil
        Open3.popen3({ "TESTAPPIO_API_TOKEN" => api_token, "API_TOKEN" => api_token }, *command) do |stdin, stdout, stderr, wait_thr|
          stdin.close

          # Read stdout and stderr concurrently to avoid deadlock when ta-cli
          # fills one buffer before we finish draining the other.
          out_thread = Thread.new do
            while (line = stdout.gets)
              line = redact_token(line, api_token)
              out << line
              UI.message(line.strip) unless line.strip.empty?
            end
          end

          err_thread = Thread.new do
            while (line = stderr.gets)
              stderr_lines << redact_token(line, api_token)
            end
          end

          out_thread.join
          err_thread.join

          exit_status = wait_thr.value
          fail_command("Error while calling ta-cli", exit_status, stderr_lines.join) unless exit_status.success?
        end
        out.join
      ensure
        # If popen3's block raised before threads joined, make sure no readers
        # are left holding pipe FDs.
        out_thread.kill if out_thread&.alive?
        err_thread.kill if err_thread&.alive?
      end

      def self.capture_cli(command, api_token)
        output, stderr, status = Open3.capture3(ENV_WITHOUT_TOKEN, *command)
        output = redact_token(output, api_token)
        stderr = redact_token(stderr, api_token)
        UI.verbose(output) unless output.empty?
        UI.verbose(stderr) unless stderr.empty?
        [output, stderr, status]
      end

      def self.fail_command(message, status, *diagnostics)
        reason = status.signaled? ? "signal #{status.termsig}" : "exit status #{status.exitstatus}"
        message = "#{message} (#{reason})"
        diagnostic = diagnostics.flat_map(&:lines).map(&:strip).reject(&:empty?).join(" | ")
        message = "#{message}: #{diagnostic}" unless diagnostic.empty?
        UI.user_error!(message)
      end

      def self.redact_token(text, api_token)
        return text if api_token.to_s.empty?

        text.gsub(api_token, "********")
      end
      private_class_method :capture_cli, :fail_command, :redact_token
    end
  end
end
