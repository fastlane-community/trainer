module XcodeLogParser
  class Options
    def self.available_options
      @options ||= [
        FastlaneCore::ConfigItem.new(key: :path,
                                     short_option: "-p",
                                     env_name: "XCODE_LOG_PARSER_PATH",
                                     default_value: ".",
                                     description: "Path to the directory that should be converted",
                                     verify_block: proc do |value|
                                       v = File.expand_path(value.to_s)
                                       UI.user_error!("Path '#{v}' is not a directory or can't be found") unless File.directory?(v)
                                     end)
      ]
    end
  end
end
