module Trainer
  class Options
    def self.available_options
      @options ||= [
        FastlaneCore::ConfigItem.new(key: :path,
                                     short_option: "-p",
                                     env_name: "TRAINER_PATH",
                                     default_value: ".",
                                     description: "Path to the directory that should be converted",
                                     verify_block: proc do |value|
                                       v = File.expand_path(value.to_s)
                                       UI.user_error!("Path '#{v}' is not a directory or can't be found") unless File.directory?(v)
                                     end),
        FastlaneCore::ConfigItem.new(key: :extension,
                                     short_option: "-e",
                                     env_name: "TRAINER_EXTENSION",
                                     default_value: ".xml",
                                     description: "The extension for the newly created file. Usually .xml or .junit",
                                     verify_block: proc do |value|
                                       UI.user_error!("extension must contain a `.`") unless value.include?(".")
                                     end),
        FastlaneCore::ConfigItem.new(key: :output_directory,
                                     short_option: "-o",
                                     env_name: "TRAINER_OUTPUT_DIRECTORY",
                                     default_value: nil,
                                     optional: true,
                                     description: "Directoy in which the xml files should be written to. Same directory as source by default")
      ]
    end
  end
end
