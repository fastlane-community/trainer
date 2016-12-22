describe Trainer do
  describe Trainer::TestParser do
    describe "Loading a file" do
      it "raises an error if the file doesn't exist" do
        expect do
          Trainer::TestParser.new("notExistent")
        end.to raise_error(/File not found at path/)
      end

      it "raises an error if FormatVersion is not supported" do
        expect do
          Trainer::TestParser.new("spec/fixtures/InvalidVersionMismatch.plist")
        end.to raise_error("Format version '0.9' is not supported, must be 1.1, 1.2")
      end

      it "loads a file without throwing an error" do
        Trainer::TestParser.new("spec/fixtures/Valid1.plist")
      end
    end

    describe "#auto_convert" do
      it "raises an error if no files were found" do
        expect do
          Trainer::TestParser.auto_convert({ path: "bin" })
        end.to raise_error("No test result files found in directory 'bin', make sure the file name ends with 'TestSummaries.plist'")
      end
    end

    describe "#tests_successful?" do
      it "returns false if tests failed" do
        tp = Trainer::TestParser.new("spec/fixtures/Valid1.plist")
        expect(tp.tests_successful?).to eq(false)
      end
    end

    describe "#data" do

      it "parses a single test target's output" do
        tp = Trainer::TestParser.new("spec/fixtures/Valid1.plist")
        expect(tp.data).to eq([
                                {
                                  project_path: "Trainer.xcodeproj",
                                  target_name: "Unit",
                                  test_name: "Unit",
                                  duration: 0.4,
                                  run_destination: {
                                    name: "iPhone 6",
                                    target_architecture: "x86_64",
                                    target_device: {
                                      identifier: "C506E86B-40D9-43D2-95FB-AAAADF799AAB",
                                      name: "iPhone 6",
                                      operating_system_version: "9.3"
                                    }
                                  },
                                  tests: [
                                    {
                                      identifier: "Unit/testExample()",
                                      test_group: "Unit",
                                      name: "testExample()",
                                      object_class: "IDESchemeActionTestSummary",
                                      status: "Success",
                                      guid: "6840EEB8-3D7A-4B2D-9A45-6955DC11D32B",
                                      duration: 0.1
                                    },
                                    {
                                      identifier: "Unit/testExample2()",
                                      test_group: "Unit",
                                      name: "testExample2()",
                                      object_class: "IDESchemeActionTestSummary",
                                      status: "Failure",
                                      guid: "B2EB311E-ED8D-4DAD-8AF0-A455A20855DF",
                                      duration: 0.1,
                                      failures: [
                                        {
                                          file_name: "/Users/liamnichols/Code/Local/Trainer/Unit/Unit.swift",
                                          line_number: 19,
                                          message: "XCTAssertTrue failed - ",
                                          performance_failure: false,
                                          failure_message: "XCTAssertTrue failed - /Users/liamnichols/Code/Local/Trainer/Unit/Unit.swift:19"
                                        }
                                      ]
                                    },
                                    {
                                      identifier: "Unit/testPerformanceExample()",
                                      test_group: "Unit",
                                      name: "testPerformanceExample()",
                                      object_class: "IDESchemeActionTestSummary",
                                      status: "Success",
                                      guid: "72D0B210-939D-4751-966F-986B6CB2660C",
                                      duration: 0.2
                                    }
                                  ],
                                  number_of_tests: 3,
                                  number_of_failures: 1
                                }
                              ])
      end
      
      it "parses multiple test targets' output without a run destination" do
        tp = Trainer::TestParser.new("spec/fixtures/TestSummaries-NoRunDestination.plist")
        expect(tp.data).to eq([
          {:project_path=>"Foo.xcodeproj",
            :target_name=>"FooTests",
            :test_name=>"FooTests",
            :run_destination=>nil,
            :duration=>0.0,
            :tests=>
            [
              {:identifier=>"BarViewControllerTests/testInit_NoPlaces_NoSelection()",
                :test_group=>"BarViewControllerTests",
                :name=>"testInit_NoPlaces_NoSelection()",
                :object_class=>"IDESchemeActionTestSummary",
                :status=>"Success",
                :guid=>"CA8D1702-A3E7-48FD-8800-5EF827F29D9F",
                :duration=>0.0}],
                :number_of_tests=>1,
                :number_of_failures=>0},
                {:project_path=>"Foo.xcodeproj",
                  :target_name=>"FooViewsTests",
                  :test_name=>"FooViewsTests",
                  :run_destination=>nil,
                  :duration=>0.0,
                  :tests=>
                  [
                    {:identifier=>"FooEmptyTableViewHelperTests/testHeaderViewObservation()",
                      :test_group=>"FooEmptyTableViewHelperTests",
                      :name=>"testHeaderViewObservation()",
                      :object_class=>"IDESchemeActionTestSummary",
                      :status=>"Success",
                      :guid=>"DAFAADD3-8495-4E1E-9869-60701DEC5BE2",
                      :duration=>0.0},
                      {:identifier=>"UIView_ExtensionsTests/testComplexViewIsVisibleInWindow()",
                        :test_group=>"UIView_ExtensionsTests",
                        :name=>"testComplexViewIsVisibleInWindow()",
                        :object_class=>"IDESchemeActionTestSummary",
                        :status=>"Success",
                        :guid=>"D03219FE-B432-4669-B957-42DA8C6FD99E",
                        :duration=>0.0},
                        {:identifier=>"UIView_ExtensionsTests/testSimpleViewIsVisibleInWindow()",
                          :test_group=>"UIView_ExtensionsTests",
                          :name=>"testSimpleViewIsVisibleInWindow()",
                          :object_class=>"IDESchemeActionTestSummary",
                          :status=>"Success",
                          :guid=>"F55CD64D-EC8C-4679-BF41-F5ECAA2CB26F",
                          :duration=>0.0}],
                          :number_of_tests=>3,
                          :number_of_failures=>0},
                          {:project_path=>"Foo.xcodeproj",
                            :target_name=>"FooFoundationTests",
                            :test_name=>"FooFoundationTests",
                            :run_destination=>nil,
                            :duration=>0.0,
                            :tests=>
                            [
                              {:identifier=>
                                "KeyValueObserverDeferredTests/testCancelReleasesObservedObject()",
                                :test_group=>"KeyValueObserverDeferredTests",
                                :name=>"testCancelReleasesObservedObject()",
                                :object_class=>"IDESchemeActionTestSummary",
                                :status=>"Success",
                                :guid=>"913E53E7-BD75-4987-B48E-4D08FB2D441B",
                                :duration=>0.0}],
                                :number_of_tests=>1,
                                :number_of_failures=>0}
                              ])
      end
    end
  end
end
