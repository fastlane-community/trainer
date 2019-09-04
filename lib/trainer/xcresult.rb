module Trainer
  module XCResult
    class AbstractObject
      attr_accessor :type

      def initialize(data)
        self.type = data["_type"]["_name"]
      end
    end

    # - ActionTestPlanRunSummaries
    #   * Kind: object
    #   * Properties:
    #     + summaries: [ActionTestPlanRunSummary]
    class ActionTestPlanRunSummaries < AbstractObject
      attr_accessor :summaries
      def initialize(data)
        self.summaries = data["summaries"]["_values"].map do |summary_data|
          ActionTestPlanRunSummary.new(summary_data)
        end
        super
      end
    end

    # - ActionAbstractTestSummary
    #   * Kind: object
    #   * Properties:
    #     + name: String?
    class ActionAbstractTestSummary < AbstractObject
      attr_accessor :name
      def initialize(data)
        self.name = data["name"]["_value"]
        super
      end
    end

    # - ActionTestPlanRunSummary
    #   * Supertype: ActionAbstractTestSummary
    #   * Kind: object
    #   * Properties:
    #     + testableSummaries: [ActionTestableSummary]
    class ActionTestPlanRunSummary < ActionAbstractTestSummary
      attr_accessor :testable_summaries
      def initialize(data)
        self.testable_summaries = data["testableSummaries"]["_values"].map do |summary_data|
          ActionTestableSummary.new(summary_data)
        end
        super
      end
    end

    # - ActionTestableSummary
    #   * Supertype: ActionAbstractTestSummary
    #   * Kind: object
    #   * Properties:
    #     + projectRelativePath: String?
    #     + targetName: String?
    #     + testKind: String?
    #     + tests: [ActionTestSummaryIdentifiableObject]
    #     + diagnosticsDirectoryName: String?
    #     + failureSummaries: [ActionTestFailureSummary]
    #     + testLanguage: String?
    #     + testRegion: String?
    class ActionTestableSummary < ActionAbstractTestSummary
      attr_accessor :project_relative_path
      attr_accessor :target_name
      attr_accessor :test_kind
      attr_accessor :tests
      def initialize(data)
        self.project_relative_path = data["projectRelativePath"]["_value"]
        self.target_name = data["targetName"]["_value"]
        self.test_kind = data["testKind"]["_value"]
        self.tests = data["tests"]["_values"].map do |tests_data|
          ActionTestSummaryIdentifiableObject.create(tests_data, self)
        end
        super
      end

      def all_tests
        return tests.map do |test|
          test.all_subtests
        end.flatten
      end
    end

    # - ActionTestSummaryIdentifiableObject
    #   * Supertype: ActionAbstractTestSummary
    #   * Kind: object
    #   * Properties:
    #     + identifier: String?
    class ActionTestSummaryIdentifiableObject < ActionAbstractTestSummary
      attr_accessor :identifier
      attr_accessor :parent
      def initialize(data, parent)
        self.identifier = data["identifier"]["_value"]
        self.parent = parent
        super(data)
      end

      def all_subtests
        raise "Not overridden"
      end

      def self.create(data, parent)
        type = data["_type"]["_name"]
        if type == "ActionTestSummaryGroup"
          return ActionTestSummaryGroup.new(data, parent)
        elsif type == "ActionTestMetadata"
          return ActionTestMetadata.new(data, parent)
        else
          raise "Unsupported type: #{type}"
        end
      end
    end

    # - ActionTestSummaryGroup
    #   * Supertype: ActionTestSummaryIdentifiableObject
    #   * Kind: object
    #   * Properties:
    #     + duration: Double
    #     + subtests: [ActionTestSummaryIdentifiableObject]
    class ActionTestSummaryGroup < ActionTestSummaryIdentifiableObject
      attr_accessor :duration
      attr_accessor :subtests
      def initialize(data, parent)
        self.duration = data["duration"]["_value"].to_f
        self.subtests = data["subtests"]["_values"].map do |subtests_data|
          ActionTestSummaryIdentifiableObject.create(subtests_data, self)
        end
        super(data, parent)
      end

      def all_subtests
        return subtests.map do |subtest|
          subtest.all_subtests
        end.flatten
      end
    end

    # - ActionTestMetadata
    #   * Supertype: ActionTestSummaryIdentifiableObject
    #   * Kind: object
    #   * Properties:
    #     + testStatus: String
    #     + duration: Double?
    #     + summaryRef: Reference?
    #     + performanceMetricsCount: Int
    #     + failureSummariesCount: Int
    #     + activitySummariesCount: Int
    class ActionTestMetadata < ActionTestSummaryIdentifiableObject
      attr_accessor :test_status
      attr_accessor :duration
      attr_accessor :performance_metrics_count
      attr_accessor :failure_summaries_count
      attr_accessor :activity_summaries_count
      def initialize(data, parent)
        self.test_status = data["testStatus"]["_value"]
        self.duration = data["duration"]["_value"].to_f
        self.performance_metrics_count = (data["performanceMetricsCount"] || {})["_value"]
        self.failure_summaries_count = (data["failureSummariesCount"] || {})["_value"]
        self.activity_summaries_count = (data["activitySummariesCount"] || {})["_value"]
        super(data, parent)
      end

      def all_subtests
        return [self]
      end
    end
  end
end