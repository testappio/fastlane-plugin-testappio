lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fastlane/plugin/testappio/version'

Gem::Specification.new do |spec|
  spec.name          = 'fastlane-plugin-testappio'
  spec.version       = Fastlane::Testappio::VERSION
  spec.author        = 'TestApp.io'
  spec.email         = 'support@testapp.io'

  spec.summary       = 'Deploy your Android & iOS to TestApp.io'
  spec.homepage      = "https://github.com/testappio/fastlane-plugin-testappio"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*"] + %w(README.md LICENSE)
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.5'

  spec.add_development_dependency('bundler', '~> 2.0')
  spec.add_development_dependency('fastlane', '~> 2.204', '>= 2.204.3')
  spec.add_development_dependency('pry', '~> 0.13')
  spec.add_development_dependency('rake', '~> 13.0')
  spec.add_development_dependency('rspec', '~> 3.0')
  spec.add_development_dependency('rspec_junit_formatter', '~> 0.4')
  spec.add_development_dependency('rubocop', '1.12.1')
  spec.add_development_dependency('rubocop-performance')
  spec.add_development_dependency('rubocop-require_tools')
  spec.add_development_dependency('simplecov', '~> 0.21')
end
