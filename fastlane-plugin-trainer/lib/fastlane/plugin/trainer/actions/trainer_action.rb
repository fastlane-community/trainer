module Fastlane
  module Actions
    class TrainerAction < Action
      def self.run(params)
        require "trainer"

        return ::Trainer::TestParser.auto_convert(params[:path])
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
        [
          FastlaneCore::ConfigItem.new(key: :path,
                                  env_name: "trainer_PATH",
                               description: "Path to the directory containing the plist files",
                             default_value: ".",
                                      type: String)
        ]
      end

      def self.is_supported?(platform)
        [:ios, :mac].include?(platform)
      end
    end
  end
end
