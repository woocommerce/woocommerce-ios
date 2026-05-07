import Foundation
import Testing
@testable import WooAIAssistant

@MainActor
struct ProductVariationsBulkUpdateToolTests {

    @Test
    func test_productVariationsBulkUpdate_when_called_with_multiple_variations_then_calls_dataSource() async throws {
        let dataSource = MockProductVariationsDataSource()
        dataSource.bulkResult = .success(BulkWriteResult(updatedIDs: [33, 34], failedItems: []))
        let tool = ProductVariationsBulkUpdateTool.make(dataSource: dataSource)
        let arguments = #"""
        {"product_id": 12, "variations": [
            {"id": 33, "regular_price": "29.99"},
            {"id": 34, "regular_price": "29.99"}
        ]}
        """#

        let result = await tool.executor(arguments, NoopWCRESTClient())

        guard case .success(let success) = result else {
            Issue.record("expected success, got \(result)")
            return
        }
        #expect(dataSource.bulkProductID == 12)
        #expect(dataSource.bulkPatches?.map(\.id) == [33, 34])
        #expect(dataSource.bulkPatches?.first?.patch.regularPrice == "29.99")
        #expect(success.uiStructured == nil)
    }

    @Test
    func test_productVariationsBulkUpdate_when_stock_quantity_set_then_patch_carries_stock_quantity() async throws {
        let dataSource = MockProductVariationsDataSource()
        dataSource.bulkResult = .success(BulkWriteResult(updatedIDs: [1, 2], failedItems: []))
        let tool = ProductVariationsBulkUpdateTool.make(dataSource: dataSource)
        let arguments = #"""
        {"product_id": 5, "variations": [
            {"id": 1, "stock_quantity": 4},
            {"id": 2, "stock_quantity": 7}
        ]}
        """#

        let result = await tool.executor(arguments, NoopWCRESTClient())

        guard case .success = result else {
            Issue.record("expected success, got \(result)")
            return
        }
        #expect(dataSource.bulkPatches?.map { $0.patch.stockQuantity } == [4, 7])
    }

    @Test
    func test_productVariationsBulkUpdate_when_variations_empty_then_returns_invalidToolCall_without_calling_dataSource() async {
        let dataSource = MockProductVariationsDataSource()
        let tool = ProductVariationsBulkUpdateTool.make(dataSource: dataSource)

        let result = await tool.executor(#"{"product_id": 12, "variations": []}"#, NoopWCRESTClient())

        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(dataSource.bulkProductID == nil)
    }

    @Test
    func test_productVariationsBulkUpdate_when_a_variation_has_no_field_then_returns_invalidToolCall() async {
        let dataSource = MockProductVariationsDataSource()
        let tool = ProductVariationsBulkUpdateTool.make(dataSource: dataSource)

        let result = await tool.executor(#"{"product_id": 12, "variations": [{"id": 33}]}"#, NoopWCRESTClient())

        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(dataSource.bulkProductID == nil)
    }

    @Test
    func test_productVariationsBulkUpdate_when_status_outside_allowlist_then_returns_invalidToolCall() async {
        let dataSource = MockProductVariationsDataSource()
        let tool = ProductVariationsBulkUpdateTool.make(dataSource: dataSource)
        let arguments = #"""
        {"product_id": 12, "variations": [{"id": 33, "status": "archived"}]}
        """#

        let result = await tool.executor(arguments, NoopWCRESTClient())

        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(dataSource.bulkProductID == nil)
    }

    @Test
    func test_productVariationsBulkUpdate_when_count_exceeds_max_then_returns_invalidToolCall() async {
        let dataSource = MockProductVariationsDataSource()
        let tool = ProductVariationsBulkUpdateTool.make(dataSource: dataSource)
        let entries = (1...101).map { #"{"id": \#($0), "regular_price": "1.00"}"# }.joined(separator: ", ")

        let result = await tool.executor(#"{"product_id": 9, "variations": [\#(entries)]}"#, NoopWCRESTClient())

        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(dataSource.bulkProductID == nil)
    }
}
