import Foundation
import Testing
@testable import WooAIAssistant

@MainActor
struct OrdersBulkUpdateToolTests {
    @Test
    func test_ordersBulkUpdate_when_status_set_then_calls_dataSource_with_ids_and_patch() async throws {
        let dataSource = MockOrdersDataSource()
        dataSource.bulkResult = .success(BulkWriteResult(updatedIDs: [1, 2], failedItems: []))
        let tool = OrdersBulkUpdateTool.make(dataSource: dataSource)

        let arguments = #"""
        {"ids": [1, 2], "patch": {"status": "completed"}}
        """#
        let result = await tool.executor(arguments, NoopWCRESTClient())

        guard case .success(let success) = result else {
            Issue.record("expected success, got \(result)")
            return
        }
        #expect(dataSource.bulkIDs == [1, 2])
        #expect(dataSource.bulkPatch?.status == "completed")
        guard case .object(let summary) = success.structured else {
            Issue.record("expected summary object")
            return
        }
        #expect(summary["updated"] == .array([.int(1), .int(2)]))
        #expect(summary["failed"] == .array([]))
    }

    @Test
    func test_ordersBulkUpdate_when_ids_empty_then_returns_invalidToolCall_without_calling_dataSource() async {
        let dataSource = MockOrdersDataSource()
        let tool = OrdersBulkUpdateTool.make(dataSource: dataSource)

        let result = await tool.executor(#"{"ids": [], "patch": {"status": "completed"}}"#, NoopWCRESTClient())

        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(dataSource.bulkIDs == nil)
    }

    @Test
    func test_ordersBulkUpdate_when_ids_count_exceeds_100_then_returns_invalidToolCall() async {
        let dataSource = MockOrdersDataSource()
        let tool = OrdersBulkUpdateTool.make(dataSource: dataSource)
        let ids = (1...101).map { String($0) }.joined(separator: ", ")

        let result = await tool.executor(#"{"ids": [\#(ids)], "patch": {"status": "processing"}}"#, NoopWCRESTClient())

        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(dataSource.bulkIDs == nil)
    }

    @Test
    func test_ordersBulkUpdate_when_patch_has_no_field_then_returns_invalidToolCall() async {
        let dataSource = MockOrdersDataSource()
        let tool = OrdersBulkUpdateTool.make(dataSource: dataSource)

        let result = await tool.executor(#"{"ids": [1], "patch": {}}"#, NoopWCRESTClient())

        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(dataSource.bulkIDs == nil)
    }

    @Test
    func test_ordersBulkUpdate_when_any_status_is_refunded_then_returns_invalidToolCall() async {
        let dataSource = MockOrdersDataSource()
        let tool = OrdersBulkUpdateTool.make(dataSource: dataSource)

        let result = await tool.executor(#"{"ids": [1, 2], "patch": {"status": "refunded"}}"#, NoopWCRESTClient())

        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(failed.reason.contains("Refunds cannot be issued"))
        #expect(dataSource.bulkIDs == nil)
    }

    @Test
    func test_ordersBulkUpdate_when_dataSource_fails_then_returns_toolFailed() async throws {
        let dataSource = MockOrdersDataSource()
        dataSource.bulkResult = .failure(TestBulkOrderError.boom)
        let tool = OrdersBulkUpdateTool.make(dataSource: dataSource)

        let result = await tool.executor(#"{"ids": [1, 2], "patch": {"status": "completed"}}"#, NoopWCRESTClient())

        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .toolFailed)
    }
}

private enum TestBulkOrderError: Error {
    case boom
}
