require 'commander'

HighLine.track_eof = false

module XcodeLogParser
  class CommandsGenerator
    include Commander::Methods

    def self.start      
      self.new.run
    end

    def run
      program :version, XcodeLogParser::VERSION
      program :description, XcodeLogParser::DESCRIPTION
      program :help, 'Author', 'Felix Krause <xcode_log_parser@krausefx.com>'
      program :help, 'Website', 'https://fastlane.tools'
      program :help, 'GitHub', 'https://github.com/KrauseFx/xcode_log_parser'
      program :help_formatter, :compact

      global_option('--verbose', 'Shows a more verbose output') { $verbose = true }

      always_trace!

      FastlaneCore::CommanderGenerator.new.generate(XcodeLogParser::Options.available_options)

      command :run do |c|
        c.syntax = 'xcode_log_parser'
        c.description = XcodeLogParser::DESCRIPTION

        c.action do |args, options|
          options = FastlaneCore::Configuration.create(XcodeLogParser::Options.available_options, options.__hash__)
          FastlaneCore::PrintTable.print_values(config: options, title: "Summary for xcode_log_parser #{XcodeLogParser::VERSION}") if $verbose
          XcodeLogParser::TestParser.auto_convert(options[:path])
        end
      end

      default_command :run

      run!
    end
  end
end
