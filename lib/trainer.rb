require 'fastlane'

require 'trainer/version'
require 'trainer/options'
require 'trainer/test_parser'
require 'trainer/junit_generator'

module Trainer
  ROOT = File.expand_path('..', __dir__)

  UI = FastlaneCore::UI
end
