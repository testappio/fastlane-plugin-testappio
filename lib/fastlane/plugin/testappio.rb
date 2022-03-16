require 'fastlane/plugin/testappio/version'

module Fastlane
  module Testappio
    # Return all .rb files inside the "actions" and "helper" directory
    def self.all_classes
      Dir[File.expand_path('**/{actions,helper}/*.rb', File.dirname(__FILE__))]
    end
  end
end

Fastlane::Testappio.all_classes.each do |current|
  require current
end
