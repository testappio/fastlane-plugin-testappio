require 'fastlane_core/ui/ui'
require 'open3'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?(:UI)

  module Helper
    class TestappioHelper
      # Check if `ta_cli` exists, install it if not
      def self.check_ta_cli
        unless system('which ta-cli > /dev/null 2>&1')
          UI.error("ta-cli not found, installing")

          unless system('curl -Ls https://github.com/testappio/cli/releases/latest/download/install | bash')
            UI.error("Error installing ta-cli")
            return false
          end
        end

        return true
      end

      # Check if there is an update available for `ta_cli`, and install it if necessary
      def self.check_update(self_update)
        version_output = `ta-cli version`
        UI.verbose(version_output)

        if version_output.include?("breaking changes")
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

        update_command = "curl -Ls https://github.com/testappio/cli/releases/latest/download/install | bash"
        update_output, = Open3.capture3(update_command)
        UI.verbose(update_output)

        if update_output.include?("ta-cli successfully installed") || update_output.include?("ta-cli has been updated")
          version_output = `ta-cli version`
          UI.verbose(version_output)

          if version_output.include?("Update necessary due to breaking changes") || version_output.include?("New version available")
            UI.user_error!("Error updating ta-cli: the version is still outdated")
          else
            UI.success("ta-cli has been updated successfully")
            return true
          end
        else
          UI.user_error!("Error updating ta-cli: #{update_output}")
        end
      end

      # Handle errors from ta-cli. Raises user_error only when stderr contains an
      # /Error/-matching line. Non-error stderr (warnings, info) is logged via UI.verbose.
      # The raised message includes the actual error lines so the user has context
      # (auth failure, provisioning issue, network error, etc.) without re-running verbose.
      def self.handle_error(errors)
        errors.each do |error|
          next unless error

          if error.include?('Error')
            UI.error(error.to_s)
          else
            UI.verbose(error.to_s)
          end
        end

        error_lines = errors.compact.select { |e| e.include?('Error') }
        return if error_lines.empty?

        UI.user_error!("Error while calling ta-cli: #{error_lines.join(' | ')}")
      end

      # Run the given command. Streams stdout to UI.message; routes stderr through
      # handle_error on non-zero exit. Masks --api_token in verbose command echo.
      #
      # Uses Open3.popen3 with the command array form (no shell interpretation), so
      # shell metacharacters in api_token / release_notes / file paths are passed
      # literally to ta-cli without need for manual escaping.
      def self.call_ta_cli(command)
        UI.message("Starting ta-cli...")
        if FastlaneCore::Globals.verbose?
          UI.verbose("ta-cli command:\n\n")
          UI.command(redact_command(command).to_s)
          UI.verbose("\n\n")
        end

        out = []
        error = []
        out_thread = nil
        err_thread = nil
        Open3.popen3(*command) do |stdin, stdout, stderr, wait_thr|
          stdin.close

          # Read stdout and stderr concurrently to avoid deadlock when ta-cli
          # fills one buffer before we finish draining the other.
          out_thread = Thread.new do
            while (line = stdout.gets)
              out << line
              UI.message(line.strip) unless line.strip.empty?
            end
          end

          err_thread = Thread.new do
            while (line = stderr.gets)
              error << line.strip
            end
          end

          out_thread.join
          err_thread.join

          exit_status = wait_thr.value
          handle_error(error) unless exit_status.success?
        end
        out.join
      ensure
        # If popen3's block raised before threads joined, make sure no readers
        # are left holding pipe FDs.
        out_thread&.kill if out_thread&.alive?
        err_thread&.kill if err_thread&.alive?
      end

      # Return a copy of the command array with --api_token=... masked.
      def self.redact_command(command)
        command.map do |arg|
          arg.kind_of?(String) && arg.start_with?("--api_token=") ? "--api_token=********" : arg
        end
      end
      private_class_method :redact_command
    end
  end
end
