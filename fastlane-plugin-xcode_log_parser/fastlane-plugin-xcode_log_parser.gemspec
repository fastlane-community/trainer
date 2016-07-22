# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fastlane/plugin/xcode_log_parser/version'

Gem::Specification.new do |spec|
  spec.name          = 'fastlane-plugin-xcode_log_parser'
  spec.version       = Fastlane::XcodeLogParser::VERSION
  spec.author        = %q{KrauseFx}
  spec.email         = %q{KrauseFx@gmail.com}

  spec.summary       = %q{Convert the Xcode plist log to a JUnit report}
  spec.homepage      = "https://github.com/KrauseFx/xcode_log_parser"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*"] + %w(README.md LICENSE)
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'xcode_log_parser', '>= 0.1.0'

  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'fastlane', '>= 1.98.0'
end
