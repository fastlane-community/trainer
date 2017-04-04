# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'trainer/version'

Gem::Specification.new do |spec|
  spec.name          = "trainer"
  spec.version       = Trainer::VERSION
  spec.authors       = ["Felix Krause"]
  spec.email         = ["fastlane@krausefx.com"]
  spec.summary       = Trainer::DESCRIPTION
  spec.description   = Trainer::DESCRIPTION
  spec.homepage      = "https://fastlane.tools"
  spec.license       = "MIT"

  spec.required_ruby_version = '>= 2.0.0'

  spec.files = Dir["lib/**/*"] + %w( README.md LICENSE )

  spec.executables   = %w(trainer)
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'plist', ">= 3.1.0", "< 4.0.0"

  # Development only
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rspec', '~> 3.1.0'
  spec.add_development_dependency 'rubocop', '~> 0.38.0'
  spec.add_development_dependency 'fastlane', '>= 2.25.0'
end
