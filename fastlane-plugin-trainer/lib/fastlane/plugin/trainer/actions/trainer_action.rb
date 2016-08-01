module Fastlane
  module Actions
    class TrainerAction < Action
      def self.run(params)
        require "trainer"

        params[:path] = Actions.lane_context[Actions::SharedValues::SCAN_DERIVED_DATA_PATH] if Actions.lane_context[Actions::SharedValues::SCAN_DERIVED_DATA_PATH]

        return ::Trainer::TestParser.auto_convert(params)
      end

      def self.description
        "Convert the Xcode plist log to a JUnit report"
      end

      def self.authors
        ["KrauseFx"]
      end

      def self.return_value
        ""
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
