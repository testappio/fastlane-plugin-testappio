require 'fastlane_core/ui/ui'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?(:UI)

  module Helper
    class TestappioHelper
      # Check if `ta_cli` exists, install it if not
      def self.check_ta_cli
        unless `which ta-cli`.include?('ta-cli')
          UI.error("ta-cli not found, installing")
          UI.command(`curl -Ls https://github.com/testappio/cli/releases/latest/download/install | bash`)
        end
      end

      # Handle errors from `ta_cli`, if contains 'Error', the process stops,
      # otherwise, just print to user console
      def self.handle_error(errors)
        fatal = false
        errors.each do |error|
          if error
            if error =~ /Error/
              UI.error(error.to_s)
              fatal = true
            else
              UI.verbose(error.to_s)
            end
          end
        end
        UI.user_error!('Error while calling ta-cli') if fatal
      end

      def self.handle_force_update(outs, command)
        fatal = false
        outs.each do |error|
          if error
            if error =~ /Update is required because of breaking changes/
              UI.command(`curl -Ls https://github.com/testappio/cli/releases/latest/download/install | bash`)
              call_ta_cli(command)
            end
          end
        end
        UI.user_error!('Error while updating ta-cli') if fatal
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
            UI.message(line.strip!)
          end
          while (line = stderr.gets)
            error << line.strip!
          end
          exit_status = wait_thr.value
          unless exit_status.success? && error.empty?
            handle_error(error)
          end
          handle_force_update(out, command)
        end
        out.join
      end
    end
  end
end
