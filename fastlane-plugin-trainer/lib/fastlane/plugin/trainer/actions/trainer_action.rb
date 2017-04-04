module Fastlane
  module Actions
    class TrainerAction < Action
      def self.run(params)
        require "trainer"

        params[:path] = Actions.lane_context[Actions::SharedValues::SCAN_GENERATED_PLIST_FILE] if Actions.lane_context[Actions::SharedValues::SCAN_GENERATED_PLIST_FILE]
        params[:path] ||= Actions.lane_context[Actions::SharedValues::SCAN_DERIVED_DATA_PATH] if Actions.lane_context[Actions::SharedValues::SCAN_DERIVED_DATA_PATH]

        resulting_paths = ::Trainer::TestParser.auto_convert(params)
        resulting_paths.each do |path, test_successful|
          UI.test_failure!("Unit tests failed") unless test_successful
        end

        return resulting_paths
      end

      def self.description
        "Convert the Xcode plist log to a JUnit report. This will raise an exception if the tests failed"
      end

      def self.authors
        ["KrauseFx"]
      end

      def self.return_value
        "A hash with the key being the path of the generated file, the value being if the tests were successful"
      end

      def self.available_options
        require "trainer/options"
        FastlaneCore::CommanderGenerator.new.generate(::Trainer::Options.available_options)
      end

      def self.is_supported?(platform)
        [:ios, :mac].include?(platform)
      end
    end
  end
end
