$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'simplecov'

formatters = [SimpleCov::Formatter::HTMLFormatter]
if ENV['CI']
  begin
    require 'simplecov-cobertura'
    formatters << SimpleCov::Formatter::CoberturaFormatter
  rescue LoadError
    warn "simplecov-cobertura not available; coverage XML will not be generated"
  end
end
SimpleCov.formatters = formatters

SimpleCov.start do
  add_filter '/spec/'
  add_filter '/version.rb'
  enable_coverage :branch
  # Enforce the coverage gate only in CI / full-suite runs. Local single-file runs
  # (e.g. `rspec spec/helper/foo_spec.rb`) would otherwise always trip the floor.
  # 100% line / 85% branch. Uncovered branches are all in defensive `ensure`-block
  # thread-cleanup paths that only fire if Open3.popen3's block raises — exercising
  # them in a unit test would require contortion with no real safety gain.
  minimum_coverage(line: 100, branch: 85) if ENV['CI'] || ENV['ENFORCE_COVERAGE']
end

# This module is only used to check the environment is currently a testing env
module SpecHelper
end

require 'fastlane' # to import the Action super class
require 'fastlane/plugin/testappio' # import the actual plugin
require 'securerandom'
require 'tempfile'
require 'stringio'

Fastlane.load_actions # load other actions (in case your plugin calls other actions or shared values)

RSpec.configure do |config|
  config.before(:each) do
    # Reset lane context between examples so default_value lookups don't leak
    Fastlane::Actions.lane_context.clear
  end

  # Integration specs hit the real ta-cli binary and are skipped by default.
  # Opt in with: bundle exec rspec --tag integration
  config.filter_run_excluding(:integration) unless ENV['INTEGRATION']
end

# Helper: build a stubbed Open3.popen3 yielding the given stdout/stderr/exit status
def stub_popen3(stdout: "", stderr: "", success: true)
  wait_thr = instance_double(Process::Waiter, value: instance_double(Process::Status, success?: success))
  allow(Open3).to receive(:popen3).and_yield(
    StringIO.new,
    StringIO.new(stdout),
    StringIO.new(stderr),
    wait_thr
  )
end
