require 'parallel'

module Trainer
  class TestParser
    attr_accessor :data

    attr_accessor :file_content

    attr_accessor :raw_json

    # Returns a hash with the path being the key, and the value
    # defining if the tests were successful
    def self.auto_convert(config)
      FastlaneCore::PrintTable.print_values(config: config,
                                             title: "Summary for trainer #{Trainer::VERSION}")

      containing_dir = config[:path]
      # Xcode < 10
      files = Dir["#{containing_dir}/**/Logs/Test/*TestSummaries.plist"]
      files += Dir["#{containing_dir}/Test/*TestSummaries.plist"]
      files += Dir["#{containing_dir}/*TestSummaries.plist"]
      # Xcode 10
      files += Dir["#{containing_dir}/**/Logs/Test/*.xcresult/TestSummaries.plist"]
      files += Dir["#{containing_dir}/Test/*.xcresult/TestSummaries.plist"]
      files += Dir["#{containing_dir}/*.xcresult/TestSummaries.plist"]
      files += Dir[containing_dir] if containing_dir.end_with?(".plist") # if it's the exact path to a plist file
      # Xcode 11
      files += Dir["#{containing_dir}/**/Logs/Test/*.xcresult"]
      files += Dir["#{containing_dir}/Test/*.xcresult"]
      files += Dir["#{containing_dir}/*.xcresult"]
      files << containing_dir if File.extname(containing_dir) == ".xcresult"

      if files.empty?
        UI.user_error!("No test result files found in directory '#{containing_dir}', make sure the file name ends with 'TestSummaries.plist' or '.xcresult'")
      end

      return_hash = {}
      files.each do |path|
        if config[:output_directory]
          FileUtils.mkdir_p(config[:output_directory])
          # Remove .xcresult or .plist extension
          if path.end_with?(".xcresult")
            filename = File.basename(path).gsub(".xcresult", config[:extension])
          else
            filename = File.basename(path).gsub(".plist", config[:extension])
          end
          to_path = File.join(config[:output_directory], filename)
        else
          # Remove .xcresult or .plist extension
          if path.end_with?(".xcresult")
            to_path = path.gsub(".xcresult", config[:extension])
          else
            to_path = path.gsub(".plist", config[:extension])
          end
        end

        tp = Trainer::TestParser.new(path, config)
        File.write(to_path, tp.to_junit)
        puts "Successfully generated '#{to_path}'"

        return_hash[to_path] = tp.tests_successful?
      end
      return_hash
    end

    def initialize(path, config = {})
      path = File.expand_path(path)
      UI.user_error!("File not found at path '#{path}'") unless File.exist?(path)

      if File.directory?(path) && path.end_with?(".xcresult")
        parse_xcresult(path, config[:xcpretty_naming])
      else
        parse_test_result(path, config[:xcpretty_naming])
      end
    end

    # Returns the JUnit report as String
    def to_junit
      JunitGenerator.new(self.data).generate
    end

    # @return [Bool] were all tests successful? Is false if at least one test failed
    def tests_successful?
      self.data.collect { |a| a[:number_of_failures] }.all?(&:zero?)
    end

    private

    def ensure_file_valid!
      format_version = self.raw_json["FormatVersion"]
      supported_versions = ["1.1", "1.2"]
      UI.user_error!("Format version '#{format_version}' is not supported, must be #{supported_versions.join(', ')}") unless supported_versions.include?(format_version)
    end

    # Returns the test group and test name from the passed summary and test
    # Pass xcpretty_naming = true to get the test naming aligned with xcpretty
    def test_group_and_name(testable_summary, test, xcpretty_naming)
      if xcpretty_naming
        group = testable_summary.target_name + "." + test.identifier.split("/")[0..-2].join(".")
        name = test.name[0..-3]
      else
        group = test.identifier.split("/")[0..-2].join(".")
        name = test.name
      end
      return group, name
    end

    def execute_cmd(cmd)
      output = `#{cmd}`
      raise "Failed to execute - #{cmd}" unless $?.success?
      return output
    end

    def parse_test_result(path, xcpretty_naming)
      self.file_content = File.read(path)
      self.raw_json = Plist.parse_xml(self.file_content)

      return if self.raw_json["FormatVersion"].to_s.length.zero? # maybe that's a useless plist file

      ensure_file_valid!
      parse_content(xcpretty_naming)
    end

    def xcresulttool_get_json(path, id = nil)
      cmd = "xcrun xcresulttool get --format json --path #{path}"
      cmd << " --id #{id}" unless id.nil?
      raw = execute_cmd(cmd)
      JSON.parse(raw)
    end

    def parse_xcresult(path, xcpretty_naming)
      require 'shellwords'
      path = Shellwords.escape(path)

      # Executes xcresulttool to get JSON format of the result bundle object
      result_bundle_object = xcresulttool_get_json(path)

      # Parses JSON into ActionsInvocationRecord to find a list of all ids for ActionTestPlanRunSummaries
      actions_invocation_record = Trainer::XCResult::ActionsInvocationRecord.new(result_bundle_object)
      test_refs = actions_invocation_record.actions.map do |action|
        action.action_result.tests_ref
      end.compact
      test_ids = test_refs.map(&:id)

      # Maps ids into ActionTestPlanRunSummaries by executing xcresulttool to get JSON
      # containing specific information for each test summary,
      summaries = Parallel.map(test_ids) do |id|
        json = xcresulttool_get_json(path, id)
        Trainer::XCResult::ActionTestPlanRunSummaries.new(json)
      end

      # Gets flat list of all ActionTestableSummary
      all_summaries = summaries.map(&:summaries).flatten
      testable_summaries = all_summaries.map(&:testable_summaries).flatten

      # Gets flat list of all ActionTestMetadata that failed
      failed_tests = testable_summaries.map do |testable_summary|
        testable_summary.all_tests.find_all { |a| a.test_status == 'Failure' }
      end.flatten

      # Find a list of all ids for ActionTestSummary
      summary_ids = failed_tests.map do |test|
        test.summary_ref.id
      end

      # Maps summary references into array of ActionTestSummary by executing xcresulttool to get JSON
      # containing more information for each test failure,
      failures = Parallel.map(summary_ids) do |id|
        json = xcresulttool_get_json(path, id)
        Trainer::XCResult::ActionTestSummary.new(json)
      end

      # Converts the ActionTestPlanRunSummaries to data for junit generator
      summaries_to_data(testable_summaries, failures, xcpretty_naming)
    end

    def summaries_to_data(testable_summaries, failures, xcpretty_naming)
      # Maps ActionTestableSummary to rows for junit generator
      rows = testable_summaries.map do |testable_summary|
        all_tests = testable_summary.all_tests.flatten

        test_rows = all_tests.map do |test|
          test_group, test_name = test_group_and_name(testable_summary, test, xcpretty_naming)
          test_row = {
            identifier: "#{test.parent.name}.#{test.name}",
            name: test_name,
            duration: test.duration,
            status: test.test_status,
            test_group: test_group,

            # These don't map to anything but keeping empty strings
            guid: ""
          }

          # Set failure message if failure found
          failure = test.find_failure(failures)
          if failure
            test_row[:failures] = [{
              file_name: failure.file_name,
              line_number: failure.line_number,
              message: failure.message,
              performance_failure: failure.performance_failure,
              failure_message: failure.failure_message
            }]
          end

          test_row
        end

        row = {
          project_path: testable_summary.project_relative_path,
          target_name: testable_summary.target_name,
          test_name: testable_summary.name,
          duration: all_tests.map(&:duration).inject(:+),
          tests: test_rows
        }

        row[:number_of_tests] = row[:tests].count
        row[:number_of_failures] = row[:tests].find_all { |a| (a[:failures] || []).count > 0 }.count

        row
      end

      self.data = rows
    end

    # Convert the Hashes and Arrays in something more useful
    def parse_content(xcpretty_naming)
      testable_summaries = self.raw_json['TestableSummaries'].collect do |summary_data|
        Trainer::TestResult::ActionTestableSummary.new(summary_data)
      end

      self.data = testable_summaries.map do |testable_summary|
        summary_row = {
          project_path: testable_summary.project_path,
          target_name: testable_summary.target_name,
          test_name: testable_summary.test_name,
          duration: testable_summary.tests.map { |current_test| current_test.duration }.inject(:+),
          tests: testable_summary.all_tests.map do |current_test|
            test_group, test_name = test_group_and_name(testable_summary, current_test, xcpretty_naming)
            current_row = {
              identifier: current_test.identifier,
                 test_group: test_group,
                 name: test_name,
              object_class: current_test.object_class,
              status: current_test.status,
              guid: current_test.summary_guid,
              duration: current_test.duration
            }
            current_row[:failures] = current_test.failure_summaries.map do |current_failure|
              {
                file_name: current_failure.file_name,
                line_number: current_failure.line_number,
                message: current_failure.message,
                performance_failure: current_failure.performance_failure,
                failure_message: current_failure.failure_message
              }
            end
            current_row
          end
        }
        summary_row[:number_of_tests] = summary_row[:tests].count
        summary_row[:number_of_failures] = summary_row[:tests].find_all { |a| (a[:failures] || []).count > 0 }.count
        summary_row
      end
    end
  end
end
