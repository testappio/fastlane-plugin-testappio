require 'fastlane_core/ui/ui'

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
        require 'open3'

        version_output = `ta-cli version`
        UI.verbose(version_output)

        if version_output.include?("breaking changes")
          if self_update
            UI.message("Updating ta-cli due to breaking changes...")
          else
            UI.user_error!("Update necessary due to breaking changes. Please update ta-cli manually or set self_update to true")
            return false
          end
        elsif version_output.include?("New version available")
          if self_update
            UI.message("Updating ta-cli...")
          else
            UI.error("New version available, but skipping update as self_update is set to false.")
            return true
          end
        else
          UI.success("ta-cli is already up-to-date")
          return true
        end

        update_command = "curl -Ls https://github.com/testappio/cli/releases/latest/download/install | bash"
        update_output, update_errors, update_status = Open3.capture3(update_command)
        UI.verbose(update_output)

        if update_output.include?("ta-cli successfully installed") || update_output.include?("ta-cli has been updated")
          version_output = `ta-cli version`
          UI.verbose(version_output)

          if version_output.include?("Update necessary due to breaking changes") || version_output.include?("New version available")
            UI.user_error!("Error updating ta-cli: the version is still outdated")
            return false
          else
            UI.success("ta-cli has been updated successfully")
            return true
          end
        else
          UI.user_error!("Error updating ta-cli: #{update_output}")
          return false
        end
      end

      # Handle errors from `ta_cli`, if contains 'Error', the process stops,
      # otherwise, just print to user console
      def self.handle_error(errors)
        errors.each do |error|
          if error
            if error =~ /Error/
              UI.error(error.to_s)
            else
              UI.verbose(error.to_s)
            end
          end
        end

        if errors.any? { |e| e =~ /Error/ }
          UI.user_error!('Error while calling ta-cli')
        elsif errors.any?
          UI.user_error!("Error while calling ta-cli: #{errors.join(', ')}")
        end
      end

      # Run the given command
      def self.call_ta_cli(command)
        UI.message("Starting ta-cli...")
        require 'open3'
        if FastlaneCore::Globals.verbose?
          UI.verbose("ta-cli command:\n\n")
          UI.command(command.to_s)
          UI.verbose("\n\n")
        end
        final_command = command.map { |arg| Shellwords.escape(arg) }.join(" ")
        out = []
        error = []
        Open3.popen3(final_command) do |stdin, stdout, stderr, wait_thr|
          while (line = stdout.gets)
            out << line
            line.strip!

            # Print output as it's generated
            UI.message(line) unless line.empty?

          end
          while (line = stderr.gets)
            error << line.strip!
          end
          exit_status = wait_thr.value
          handle_error(error) unless exit_status.success?
        end
        out.join
      end

    end
  end
end
