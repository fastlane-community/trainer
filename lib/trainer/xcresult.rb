module Trainer
  module XCResult
    # Model attributes and relationships taken from running the following command:
    # xcrun xcresulttool formatDescription

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
        return tests.map(&:all_subtests).flatten
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
        return subtests.map(&:all_subtests).flatten
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

    # - ActionsInvocationRecord
    #   * Kind: object
    #   * Properties:
    #     + metadataRef: Reference?
    #     + metrics: ResultMetrics
    #     + issues: ResultIssueSummaries
    #     + actions: [ActionRecord]
    #     + archive: ArchiveInfo?
    class ActionsInvocationRecord < AbstractObject
      attr_accessor :actions
      attr_accessor :issues
      def initialize(data)
        self.actions = data["actions"]["_values"].map do |action_data|
          ActionRecord.new(action_data)
        end
        self.issues = ResultIssueSummaries.new(data["issues"])
        super
      end
    end

    # - ActionRecord
    #   * Kind: object
    #   * Properties:
    #     + schemeCommandName: String
    #     + schemeTaskName: String
    #     + title: String?
    #     + startedTime: Date
    #     + endedTime: Date
    #     + runDestination: ActionRunDestinationRecord
    #     + buildResult: ActionResult
    #     + actionResult: ActionResult
    class ActionRecord < AbstractObject
      attr_accessor :scheme_command_name
      attr_accessor :scheme_task_name
      attr_accessor :title
      attr_accessor :build_result
      attr_accessor :action_result
      def initialize(data)
        self.scheme_command_name = data["schemeCommandName"]["_value"]
        self.scheme_task_name = data["schemeTaskName"]["_value"]
        self.title = data["title"]["_value"]
        self.build_result = ActionResult.new(data["buildResult"])
        self.action_result = ActionResult.new(data["actionResult"])
        super
      end
    end

    # - ActionResult
    #   * Kind: object
    #   * Properties:
    #     + resultName: String
    #     + status: String
    #     + metrics: ResultMetrics
    #     + issues: ResultIssueSummaries
    #     + coverage: CodeCoverageInfo
    #     + timelineRef: Reference?
    #     + logRef: Reference?
    #     + testsRef: Reference?
    #     + diagnosticsRef: Reference?
    class ActionResult < AbstractObject
      attr_accessor :result_name
      attr_accessor :status
      attr_accessor :issues
      attr_accessor :timeline_ref
      attr_accessor :log_ref
      attr_accessor :tests_ref
      attr_accessor :diagnostics_ref
      def initialize(data)
        self.result_name = data["resultName"]["_value"]
        self.status = data["status"]["_value"]
        self.issues = ResultIssueSummaries.new(data["issues"])

        self.timeline_ref = Reference.new(data["timelineRef"]) if data["timelineRef"]
        self.log_ref = Reference.new(data["logRef"]) if data["logRef"]
        self.tests_ref = Reference.new(data["testsRef"]) if data["testsRef"]
        self.diagnostics_ref = Reference.new(data["diagnosticsRef"]) if data["diagnosticsRef"]
        super
      end
    end

    # - Reference
    #   * Kind: object
    #   * Properties:
    #     + id: String
    #     + targetType: TypeDefinition?
    class Reference < AbstractObject
      attr_accessor :id
      attr_accessor :target_type
      def initialize(data)
        self.id = data["id"]["_value"]
        self.target_type = TypeDefinition.new(data["targetType"]) if data["targetType"]
        super
      end
    end

    # - TypeDefinition
    #   * Kind: object
    #   * Properties:
    #     + name: String
    #     + supertype: TypeDefinition?
    class TypeDefinition < AbstractObject
      attr_accessor :name
      attr_accessor :supertype
      def initialize(data)
        self.name = data["name"]["_value"]
        self.supertype = TypeDefinition.new(data["supertype"]) if data["supertype"]
        super
      end
    end

    # - DocumentLocation
    #   * Kind: object
    #   * Properties:
    #     + url: String
    #     + concreteTypeName: String
    class DocumentLocation < AbstractObject
      attr_accessor :url
      attr_accessor :concrete_type_name
      def initialize(data)
        self.url = data["url"]["_value"]
        self.concrete_type_name = data["concreteTypeName"]["_value"]
        super
      end
    end

    # - IssueSummary
    #   * Kind: object
    #   * Properties:
    #     + issueType: String
    #     + message: String
    #     + producingTarget: String?
    #     + documentLocationInCreatingWorkspace: DocumentLocation?
    class IssueSummary < AbstractObject
      attr_accessor :issue_type
      attr_accessor :message
      attr_accessor :producing_target
      attr_accessor :document_location_in_creating_workspace
      def initialize(data)
        self.issue_type = data["issueType"]["_value"]
        self.message = data["message"]["_value"]
        self.producing_target = data["producingTarget"]["_value"]
        self.document_location_in_creating_workspace = DocumentLocation.new(data["documentLocationInCreatingWorkspace"]) if data["documentLocationInCreatingWorkspace"]
        super
      end
    end

    # - ResultIssueSummaries
    #   * Kind: object
    #   * Properties:
    #     + analyzerWarningSummaries: [IssueSummary]
    #     + errorSummaries: [IssueSummary]
    #     + testFailureSummaries: [TestFailureIssueSummary]
    #     + warningSummaries: [IssueSummary]
    class ResultIssueSummaries < AbstractObject
      attr_accessor :analyzer_warning_summaries
      attr_accessor :error_summaries
      attr_accessor :test_failure_summaries
      attr_accessor :warning_summaries
      def initialize(data)
        self.analyzer_warning_summaries = data["analyzerWarningSummaries"]["_values"].map do |summary_data|
          IssueSummary.new(summary_data)
        end if data["analyzerWarningSummaries"]
        self.error_summaries = data["errorSummaries"]["_values"].map do |summary_data|
          IssueSummary.new(summary_data)
        end if data["errorSummaries"]
        self.test_failure_summaries = data["testFailureSummaries"]["_values"].map do |summary_data|
          TestFailureIssueSummary.new(summary_data)
        end if data["testFailureSummaries"]
        self.warning_summaries = data["warningSummaries"]["_values"].map do |summary_data|
          IssueSummary.new(summary_data)
        end if data["warningSummaries"]
        super
      end
    end

    # - TestFailureIssueSummary
    #   * Supertype: IssueSummary
    #   * Kind: object
    #   * Properties:
    #     + testCaseName: String
    class TestFailureIssueSummary < IssueSummary
      attr_accessor :test_case_name
      def initialize(data)
        self.test_case_name = data["testCaseName"]["_value"]
        super
      end
    end
  end
end
