import Foundation
import Testing
@testable import WooAIAssistant

@MainActor
struct ProductsBulkUpdateToolTests {
    @Test
    func test_productsBulkUpdate_when_status_set_then_calls_dataSource_with_ids_and_patch() async throws {
        let dataSource = MockProductsDataSource()
        dataSource.bulkResult = .success(BulkWriteResult(updatedIDs: [10, 11], failedItems: []))
        let tool = ProductsBulkUpdateTool.make(dataSource: dataSource)

        let result = await tool.executor(#"{"ids": [10, 11], "patch": {"status": "draft"}}"#, NoopWCRESTClient())

        guard case .success(let success) = result else {
            Issue.record("expected success, got \(result)")
            return
        }
        #expect(dataSource.bulkIDs == [10, 11])
        #expect(dataSource.bulkPatch?.status == "draft")
        guard case .object(let summary) = success.structured else {
            Issue.record("expected summary object")
            return
        }
        #expect(summary["updated"] == .array([.int(10), .int(11)]))
        #expect(summary["failed"] == .array([]))
    }

    @Test
    func test_productsBulkUpdate_when_stock_quantity_set_then_patch_carries_stock_quantity() async throws {
        let dataSource = MockProductsDataSource()
        dataSource.bulkResult = .success(BulkWriteResult(updatedIDs: [1], failedItems: []))
        let tool = ProductsBulkUpdateTool.make(dataSource: dataSource)

        let result = await tool.executor(#"{"ids": [1], "patch": {"stock_quantity": 0}}"#, NoopWCRESTClient())

        guard case .success = result else {
            Issue.record("expected success, got \(result)")
            return
        }
        #expect(dataSource.bulkPatch?.stockQuantity == 0)
    }

    @Test
    func test_productsBulkUpdate_when_partial_failure_then_summary_includes_failed_item_message() async throws {
        let dataSource = MockProductsDataSource()
        dataSource.bulkResult = .success(BulkWriteResult(updatedIDs: [10],
                                                         failedItems: [.init(id: 11, message: "Product #11 was not found")]))
        let tool = ProductsBulkUpdateTool.make(dataSource: dataSource)

        let result = await tool.executor(#"{"ids": [10, 11], "patch": {"status": "draft"}}"#, NoopWCRESTClient())

        guard case .success(let success) = result,
              case .object(let summary) = success.structured else {
            Issue.record("expected summary object, got \(result)")
            return
        }
        #expect(summary["updated"] == .array([.int(10)]))
        #expect(summary["failed"] == .array([
            .object([
                "id": .int(11),
                "message": .string("Product #11 was not found")
            ])
        ]))
    }

    @Test
    func test_productsBulkUpdate_when_ids_count_exceeds_100_then_returns_validationError() async {
        let dataSource = MockProductsDataSource()
        let tool = ProductsBulkUpdateTool.make(dataSource: dataSource)
        let ids = (1...101).map { String($0) }.joined(separator: ", ")

        let result = await tool.executor(#"{"ids": [\#(ids)], "patch": {"status": "draft"}}"#, NoopWCRESTClient())

        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(dataSource.bulkIDs == nil)
    }

    @Test
    func test_productsBulkUpdate_when_ids_empty_then_returns_validationError() async {
        let dataSource = MockProductsDataSource()
        let tool = ProductsBulkUpdateTool.make(dataSource: dataSource)

        let result = await tool.executor(#"{"ids": [], "patch": {"status": "draft"}}"#, NoopWCRESTClient())

        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(dataSource.bulkIDs == nil)
    }

    @Test
    func test_productsBulkUpdate_when_dataSource_fails_then_returns_toolFailed() async throws {
        let dataSource = MockProductsDataSource()
        dataSource.bulkResult = .failure(TestError.boom)
        let tool = ProductsBulkUpdateTool.make(dataSource: dataSource)

        let result = await tool.executor(#"{"ids": [1], "patch": {"status": "draft"}}"#, NoopWCRESTClient())

        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .toolFailed)
    }
}

private enum TestError: Error {
    case boom
}
