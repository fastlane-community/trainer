module Fastlane
  module Actions
    class XcodeLogParserAction < Action
      def self.run(params)
        require "xcode_log_parser"

        return ::XcodeLogParser::TestParser.auto_convert(params[:path])
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
                                  env_name: "XCODE_LOG_PARSER_PATH",
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
