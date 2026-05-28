lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fastlane/plugin/testappio/version'

Gem::Specification.new do |spec|
  spec.name          = 'fastlane-plugin-testappio'
  spec.version       = Fastlane::Testappio::VERSION
  spec.author        = 'TestApp.io'
  spec.email         = 'support@testapp.io'

  spec.summary       = 'Deploy your Android & iOS to TestApp.io'
  spec.description   = <<~DESC
    A Fastlane plugin that uploads Android (.apk) and iOS (.ipa) builds to TestApp.io,
    notifying your team for testing and feedback. Wraps the ta-cli binary to provide a
    single upload_to_testappio Fastlane action with platform detection, release notes
    from git, and selective team notifications.
  DESC
  spec.homepage      = "https://github.com/testappio/fastlane-plugin-testappio"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*"] + %w(README.md LICENSE CHANGELOG.md)
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 3.0'

  spec.metadata = {
    "rubygems_mfa_required" => "true",
    "source_code_uri"       => "https://github.com/testappio/fastlane-plugin-testappio",
    "changelog_uri"         => "https://github.com/testappio/fastlane-plugin-testappio/blob/main/CHANGELOG.md",
    "bug_tracker_uri"       => "https://github.com/testappio/fastlane-plugin-testappio/issues"
  }

  spec.add_development_dependency('bundler', '~> 2.0')
  spec.add_development_dependency('fastlane', '~> 2.217')
  spec.add_development_dependency('pry', '~> 0.14')
  spec.add_development_dependency('rake', '~> 13.0')
  spec.add_development_dependency('rspec', '~> 3.0')
  spec.add_development_dependency('rspec_junit_formatter', '~> 0.6')
  spec.add_development_dependency('rubocop', '~> 1.50')
  spec.add_development_dependency('rubocop-performance', '~> 1.20')
  spec.add_development_dependency('simplecov', '~> 0.22')
  spec.add_development_dependency('simplecov-cobertura', '~> 3.1')
end
