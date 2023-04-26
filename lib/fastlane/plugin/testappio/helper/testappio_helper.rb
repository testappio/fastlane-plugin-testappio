require 'fastlane_core/ui/ui'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?(:UI)

  module Helper
    class TestappioHelper
      def self.check_ta_cli
        return if system('which ta-cli > /dev/null 2>&1')

        UI.error("ta-cli not found, installing")
        raise 'Error installing ta-cli' unless system('curl -Ls https://github.com/testappio/cli/releases/latest/download/install | bash')
      end

      def self.handle_error(errors)
        any_error = false
        errors.each do |error|
          if error
            if error =~ /Error/
              UI.error(error.to_s)
              any_error = true
            else
              UI.verbose(error.to_s)
            end
          end
        end

        UI.user_error!('Error while calling ta-cli') if any_error
      end

      def self.handle_force_update(outs, command)
        return unless outs.any? { |out| out =~ /Update is required because of breaking changes/ }

        UI.command('curl -Ls https://github.com/testappio/cli/releases/latest/download/install | bash') &&
          call_ta_cli(command)
        UI.user_error!('Error while updating ta-cli')
      end

      def self.call_ta_cli(command)
        UI.message("Starting ta-cli...")

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
          handle_force_update(out, command) if error.empty?
          handle_error(error) unless exit_status.success?
        end
        out.join
      end
    end
  end
end
