# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fastlane/plugin/trainer/version'

Gem::Specification.new do |spec|
  spec.name          = 'fastlane-plugin-trainer'
  spec.version       = Fastlane::Trainer::VERSION
  spec.author        = %q{KrauseFx}
  spec.email         = %q{KrauseFx@gmail.com}

  spec.summary       = "Convert xcodebuild plist files to JUnit reports"
  spec.homepage      = "https://github.com/KrauseFx/trainer"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*"] + %w(README.md LICENSE)
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'trainer', '>= 0.2.0'

  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'fastlane', '>= 1.98.0'
end
