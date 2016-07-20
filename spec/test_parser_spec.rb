describe XcodeLogParser do
  describe XcodeLogParser::TestParser do
    describe "Loading a file" do
      it "raises an error if the file doesn't exist" do
        expect do
          XcodeLogParser::TestParser.new("notExistent")
        end.to raise_error(/File not found at path/)
      end

      it "raises an error if FormatVersion is not supported" do
        expect do
          XcodeLogParser::TestParser.new("spec/fixtures/InvalidVersionMismatch.plist")
        end.to raise_error("Format version 0.9 is not supported")
      end

      it "loads a file without throwing an error" do
        XcodeLogParser::TestParser.new("spec/fixtures/Valid1.plist")
      end
    end

    describe "Stores the data in a useful format" do
      it "works as expected" do
        tp = XcodeLogParser::TestParser.new("spec/fixtures/Valid1.plist")
        expect(tp.data).to eq([
                                {
                                  project_path: "Themoji.xcodeproj",
                                  target_name: "Unit",
                                  test_name: "Unit",
                                  tests: [
                                    {
                                      identifier: "Unit/testExample()",
                                      name: "testExample()",
                                      object_class: "IDESchemeActionTestSummary",
                                      status: "Success",
                                      guid: "4A24BFED-03E6-4FBE-BC5E-2D80023C06B4"
                                    },
                                    {
                                      identifier: "Unit/testExample2()",
                                      name: "testExample2()",
                                      object_class: "IDESchemeActionTestSummary",
                                      status: "Failure",
                                      guid: "B6AE5BAD-2F01-4D34-BEC8-6AB07472A13B",
                                      failures: [
                                        {
                                          file_name: "/Users/krausefx/Developer/themoji/Unit/Unit.swift",
                                          line_number: 34,
                                          message: "XCTAssertTrue failed - ",
                                          performance_failure: false,
                                          failure_message: "XCTAssertTrue failed - /Users/krausefx/Developer/themoji/Unit/Unit.swift:34"
                                        }
                                      ]
                                    },
                                    {
                                      identifier: "Unit/testPerformanceExample()",
                                      name: "testPerformanceExample()",
                                      object_class: "IDESchemeActionTestSummary",
                                      status: "Success",
                                      guid: "777C5F98-023B-4F99-B98D-20DDE724160E"
                                    }
                                  ],
                                  number_of_tests: 3,
                                  number_of_failures: 1
                                }
                              ])
      end
    end
  end
end
