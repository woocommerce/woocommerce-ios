import Foundation
import Fakes
import Testing
import Yosemite
@testable import WooAIAssistant

@MainActor
struct OrdersUpdateToolTests {
    @Test
    func test_ordersUpdate_when_status_completed_then_calls_dataSource() async throws {
        let dataSource = MockOrdersDataSource()
        dataSource.orderResult = .success(makeOrder(id: 7, status: .completed))
        let tool = OrdersUpdateTool.make(dataSource: dataSource)

        let result = await tool.executor(#"{"id": 7, "status": "completed"}"#, NoopWCRESTClient())

        guard case .success = result else {
            Issue.record("expected success, got \(result)")
            return
        }
        #expect(dataSource.updatedOrderID == 7)
        #expect(dataSource.updatedOrderPatch?.status == "completed")
    }

    @Test
    func test_ordersUpdate_when_status_outside_allowlist_then_returns_invalidToolCall_without_calling_dataSource() async {
        let dataSource = MockOrdersDataSource()
        let tool = OrdersUpdateTool.make(dataSource: dataSource)

        let result = await tool.executor(#"{"id": 1, "status": "shipped"}"#, NoopWCRESTClient())

        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(dataSource.updatedOrderID == nil)
    }

    @Test
    func test_ordersUpdate_when_field_outside_allowlist_then_not_passed_to_dataSource() async throws {
        let dataSource = MockOrdersDataSource()
        dataSource.orderResult = .success(makeOrder(id: 8, status: .processing))
        let tool = OrdersUpdateTool.make(dataSource: dataSource)

        let arguments = #"""
        {"id": 8, "status": "processing", "discount_total": "99.99", "_method": "delete"}
        """#
        let result = await tool.executor(arguments, NoopWCRESTClient())

        guard case .success = result else {
            Issue.record("expected success, got \(result)")
            return
        }
        #expect(dataSource.updatedOrderPatch?.status == "processing")
        #expect(dataSource.updatedOrderPatch?.billingEmail == nil)
    }

    @Test
    func test_ordersUpdate_when_only_id_provided_then_returns_invalidToolCall() async {
        let dataSource = MockOrdersDataSource()
        let tool = OrdersUpdateTool.make(dataSource: dataSource)

        let result = await tool.executor(#"{"id": 1}"#, NoopWCRESTClient())

        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(dataSource.updatedOrderID == nil)
    }

    @Test
    func test_ordersUpdate_when_billing_email_set_then_patch_carries_billingEmail() async throws {
        let dataSource = MockOrdersDataSource()
        dataSource.orderResult = .success(makeOrder(id: 2))
        let tool = OrdersUpdateTool.make(dataSource: dataSource)

        let result = await tool.executor(#"{"id": 2, "billing_email": "buyer@example.com"}"#, NoopWCRESTClient())

        guard case .success = result else {
            Issue.record("expected success, got \(result)")
            return
        }
        #expect(dataSource.updatedOrderPatch?.billingEmail == "buyer@example.com")
    }

    @Test
    func test_ordersUpdate_when_status_is_refunded_then_returns_invalidToolCall() async {
        let dataSource = MockOrdersDataSource()
        let tool = OrdersUpdateTool.make(dataSource: dataSource)

        let result = await tool.executor(#"{"id": 1, "status": "refunded"}"#, NoopWCRESTClient())

        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(failed.reason.contains("Refunds cannot be issued"))
        #expect(dataSource.updatedOrderID == nil)
    }
}

@MainActor
final class MockOrdersDataSource: AssistantOrdersDataSourceProtocol {
    var orderResult: Result<Order, Error> = .failure(TestOrderError.boom)
    var bulkResult = Result<BulkWriteResult, Error>.success(BulkWriteResult(updatedIDs: [], failedItems: []))
    private(set) var updatedOrderID: Int64?
    private(set) var updatedOrderPatch: OrderUpdatePatch?
    private(set) var bulkIDs: [Int64]?
    private(set) var bulkPatch: OrderUpdatePatch?

    func updateOrder(id: Int64, patch: OrderUpdatePatch) async -> Result<Order, Error> {
        updatedOrderID = id
        updatedOrderPatch = patch
        return orderResult
    }

    func bulkUpdateOrders(ids: [Int64], patch: OrderUpdatePatch) async -> Result<BulkWriteResult, Error> {
        bulkIDs = ids
        bulkPatch = patch
        return bulkResult
    }
}

private func makeOrder(id: Int64, status: OrderStatusEnum = .processing) -> Order {
    Order.fake().copy(siteID: 123,
                      orderID: id,
                      number: "\(id)",
                      status: status,
                      dateCreated: Date(timeIntervalSince1970: 1_700_000_000))
}

private enum TestOrderError: Error {
    case boom
}
