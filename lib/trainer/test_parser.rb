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
      files += Dir["#{containing_dir}/*.xcresult"]

      if files.empty?
        UI.user_error!("No test result files found in directory '#{containing_dir}', make sure the file name ends with 'TestSummaries.plist'")
      end

      return_hash = {}
      files.each do |path|
        if config[:output_directory]
          FileUtils.mkdir_p(config[:output_directory])
          filename = File.basename(path).gsub(".plist", config[:extension])
          to_path = File.join(config[:output_directory], filename)
        else
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

      if File.directory?(path)
        parse_xcresult(path)
      else
        self.file_content = File.read(path)
        self.raw_json = Plist.parse_xml(self.file_content)

        return if self.raw_json["FormatVersion"].to_s.length.zero? # maybe that's a useless plist file

        ensure_file_valid!
        parse_content(config[:xcpretty_naming])
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

    # Converts the raw plist test structure into something that's easier to enumerate
    def unfold_tests(data)
      # `data` looks like this
      # => [{"Subtests"=>
      #  [{"Subtests"=>
      #     [{"Subtests"=>
      #        [{"Duration"=>0.4,
      #          "TestIdentifier"=>"Unit/testExample()",
      #          "TestName"=>"testExample()",
      #          "TestObjectClass"=>"IDESchemeActionTestSummary",
      #          "TestStatus"=>"Success",
      #          "TestSummaryGUID"=>"4A24BFED-03E6-4FBE-BC5E-2D80023C06B4"},
      #         {"FailureSummaries"=>
      #           [{"FileName"=>"/Users/krausefx/Developer/themoji/Unit/Unit.swift",
      #             "LineNumber"=>34,
      #             "Message"=>"XCTAssertTrue failed - ",
      #             "PerformanceFailure"=>false}],
      #          "TestIdentifier"=>"Unit/testExample2()",

      tests = []
      data.each do |current_hash|
        if current_hash["Subtests"]
          tests += unfold_tests(current_hash["Subtests"])
        end
        if current_hash["TestStatus"]
          tests << current_hash
        end
      end
      return tests
    end

    # Returns the test group and test name from the passed summary and test
    # Pass xcpretty_naming = true to get the test naming aligned with xcpretty
    def test_group_and_name(testable_summary, test, xcpretty_naming)
      if xcpretty_naming
        group = testable_summary["TargetName"] + "." + test["TestIdentifier"].split("/")[0..-2].join(".")
        name = test["TestName"][0..-3]
      else
        group = test["TestIdentifier"].split("/")[0..-2].join(".")
        name = test["TestName"]
      end
      return group, name
    end

    def parse_xcresult(path)
      result_bundle_object_raw = `xcrun xcresulttool get --format json --path #{path}`
      result_bundle_object = JSON.parse(result_bundle_object_raw)

      actions = result_bundle_object["actions"]["_values"]
      ids = actions.map do |action|
        tests_ref = action["actionResult"]["testsRef"] || {}
        tests_ref_id = tests_ref["id"] || {}
        tests_ref_id["_value"]
      end.compact

      xcresult_summaries = ids.map do |id|
        raw = `xcrun xcresulttool get --format json --path #{path} --id #{id}`
        json = JSON.parse(raw)
        parse_xcresult_summaries_content(json)
      end

      # NOT SURE IF THERE WILL BE MORE THAN ONE HERE
      self.data = xcresult_summaries.flatten
      puts "data: #{self.data}"
    end

    def parse_xcresult_summaries_content(json)
      summaries = json["summaries"]["_values"]
      testable_summaries_raw = summaries.map do |summary|
        summary["testableSummaries"]["_values"]
      end.flatten

      return testable_summaries_raw.map do |testable_summary|
        name = testable_summary["name"]["_value"]
        target_name = testable_summary["targetName"]["_value"]
        project_path = testable_summary["projectRelativePath"]["_value"]

        puts "name=#{name}, target_name=#{target_name}"

        tests_raw = testable_summary["tests"]["_values"]
        tests = tests_raw.map do |test|
          group_name = test["name"]["_value"]
          duration = test["duration"]["_value"]

          subtest_groups_raw = (test["subtests"] || {})["_values"] || []
          subtest_groups = subtest_groups_raw.map do |subtest_group|
            name = subtest_group["name"]["_value"]

            subtest_tests_raw = (subtest_group["subtests"] || {})["_values"] || []
            subtest_tests_raw.map do |subtest_test|
              classname = subtest_test["name"]["_value"]
              duration = subtest_test["duration"]["_value"]

              subtest_methods_raw = (subtest_test["subtests"] || {})["_values"] || []
              subtest_methods_raw.map do |subtest_method|
                name = subtest_method["name"]["_value"]
                duration = subtest_method["duration"]["_value"]

                {
                name: name,
                duration: duration,

                # ???
                identifier: "",
                test_group: classname,
                status: "Success",
                guid:" "
              }
              end
            end.flatten
          end.flatten

          subtest_groups
        end.flatten

        puts "tests: #{tests}"

        row = {
          project_path: project_path,
          target_name: target_name,
          test_name: name,

          duration: tests.map{ |test| test[:duration] }.inject(:+),
          tests: tests,

          number_of_tests: 0,
          number_of_failures: 0
        }
        
        row
      end

      # summary_row = {
      #     project_path: content["ProjectPath"],
      #     target_name: content["TargetName"],
      #     test_name: content["TestName"],
        #   duration: testable_summary["Tests"].map { |current_test| current_test["Duration"] }.inject(:+),
        #   tests: unfold_tests(testable_summary["Tests"]).collect do |current_test|
        #     test_group, test_name = test_group_and_name(testable_summary, current_test, xcpretty_naming)
        #     current_row = {
        #       identifier: current_test["TestIdentifier"],
        #          test_group: test_group,
        #          name: test_name,
        #       object_class: current_test["TestObjectClass"],
        #       status: current_test["TestStatus"],
        #       guid: current_test["TestSummaryGUID"],
        #       duration: current_test["Duration"]
        #     }
        #     if current_test["FailureSummaries"]
        #       current_row[:failures] = current_test["FailureSummaries"].collect do |current_failure|
        #         {
        #           file_name: current_failure['FileName'],
        #           line_number: current_failure['LineNumber'],
        #           message: current_failure['Message'],
        #           performance_failure: current_failure['PerformanceFailure'],
        #           failure_message: "#{current_failure['Message']} (#{current_failure['FileName']}:#{current_failure['LineNumber']})"
        #         }
        #       end
        #     end
        #     current_row
        #   end
        # }
        # summary_row[:number_of_tests] = summary_row[:tests].count
        # summary_row[:number_of_failures] = summary_row[:tests].find_all { |a| (a[:failures] || []).count > 0 }.count
        # summary_row
    end

    def parse_subtests(subtests, tabs)
      subtests.map do |subtest|
        type = subtest["_type"]["_name"]
        name = subtest["name"]["_value"]
        duration = subtest["duration"]["_value"]
        puts "#{tabs}type=#{type} name=#{name} duration=#{duration}"

        obj = {
          type: type,
          "TestName": name,
          "Duration" => duration,
          subtests: []
        }

        if subtest["subtests"]
          subtests = subtest["subtests"]["_values"]
          obj[:subtests] = parse_subtests(subtests, tabs + "\t")
        end

        obj
      end
    end

    # Convert the Hashes and Arrays in something more useful
    def parse_content(xcpretty_naming)
      self.data = self.raw_json["TestableSummaries"].collect do |testable_summary|
        summary_row = {
          project_path: testable_summary["ProjectPath"],
          target_name: testable_summary["TargetName"],
          test_name: testable_summary["TestName"],
          duration: testable_summary["Tests"].map { |current_test| current_test["Duration"] }.inject(:+),
          tests: unfold_tests(testable_summary["Tests"]).collect do |current_test|
            test_group, test_name = test_group_and_name(testable_summary, current_test, xcpretty_naming)
            current_row = {
              identifier: current_test["TestIdentifier"],
                 test_group: test_group,
                 name: test_name,
              object_class: current_test["TestObjectClass"],
              status: current_test["TestStatus"],
              guid: current_test["TestSummaryGUID"],
              duration: current_test["Duration"]
            }
            if current_test["FailureSummaries"]
              current_row[:failures] = current_test["FailureSummaries"].collect do |current_failure|
                {
                  file_name: current_failure['FileName'],
                  line_number: current_failure['LineNumber'],
                  message: current_failure['Message'],
                  performance_failure: current_failure['PerformanceFailure'],
                  failure_message: "#{current_failure['Message']} (#{current_failure['FileName']}:#{current_failure['LineNumber']})"
                }
              end
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
