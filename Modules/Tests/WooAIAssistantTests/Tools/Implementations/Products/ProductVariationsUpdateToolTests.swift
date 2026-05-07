import Foundation
import Fakes
import Testing
import Yosemite
@testable import WooAIAssistant

@MainActor
struct ProductVariationsUpdateToolTests {
    @Test
    func test_productVariationsUpdate_when_regular_price_set_then_calls_dataSource_with_both_ids() async throws {
        let dataSource = MockProductVariationsDataSource()
        dataSource.variationResult = .success(makeVariation(id: 33, parentID: 12))
        let tool = ProductVariationsUpdateTool.make(dataSource: dataSource)

        let result = await tool.executor(#"{"product_id": 12, "id": 33, "regular_price": "29.99"}"#, NoopWCRESTClient())

        guard case .success = result else {
            Issue.record("expected success, got \(result)")
            return
        }
        #expect(dataSource.updatedProductID == 12)
        #expect(dataSource.updatedVariationID == 33)
        #expect(dataSource.updatedVariationPatch?.regularPrice == "29.99")
    }

    @Test
    func test_productVariationsUpdate_when_success_then_card_family_is_productVariation() async throws {
        let dataSource = MockProductVariationsDataSource()
        dataSource.variationResult = .success(makeVariation(id: 33, parentID: 12))
        let tool = ProductVariationsUpdateTool.make(dataSource: dataSource)

        let result = await tool.executor(#"{"product_id": 12, "id": 33, "regular_price": "29.99"}"#, NoopWCRESTClient())

        guard case .success(let success) = result else {
            Issue.record("expected success, got \(result)")
            return
        }
        let cards = try #require(success.uiStructured?.cards)
        #expect(cards.allSatisfy { $0.family == .productVariation })
    }

    @Test
    func test_productVariationsUpdate_when_stock_quantity_set_then_patch_carries_stock_quantity() async throws {
        let dataSource = MockProductVariationsDataSource()
        dataSource.variationResult = .success(makeVariation(id: 33, parentID: 12))
        let tool = ProductVariationsUpdateTool.make(dataSource: dataSource)

        let result = await tool.executor(#"{"product_id": 12, "id": 33, "stock_quantity": 7}"#, NoopWCRESTClient())

        guard case .success = result else {
            Issue.record("expected success, got \(result)")
            return
        }
        #expect(dataSource.updatedVariationPatch?.stockQuantity == 7)
    }

    @Test
    func test_productVariationsUpdate_when_stock_status_outside_allowlist_then_returns_invalidToolCall() async {
        let dataSource = MockProductVariationsDataSource()
        let tool = ProductVariationsUpdateTool.make(dataSource: dataSource)

        let result = await tool.executor(#"{"product_id": 1, "id": 2, "stock_status": "delayed"}"#, NoopWCRESTClient())

        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(dataSource.updatedVariationID == nil)
    }

    @Test
    func test_productVariationsUpdate_when_field_outside_allowlist_then_not_passed_to_dataSource() async throws {
        let dataSource = MockProductVariationsDataSource()
        dataSource.variationResult = .success(makeVariation(id: 33, parentID: 12))
        let tool = ProductVariationsUpdateTool.make(dataSource: dataSource)

        let arguments = #"""
        {"product_id": 12, "id": 33, "regular_price": "1.00", "weight": "5", "dimensions": {"length": "1"}}
        """#
        let result = await tool.executor(arguments, NoopWCRESTClient())

        guard case .success = result else {
            Issue.record("expected success, got \(result)")
            return
        }
        #expect(dataSource.updatedVariationPatch?.regularPrice == "1.00")
        #expect(dataSource.updatedVariationPatch?.sku == nil)
    }

    @Test
    func test_productVariationsUpdate_when_only_required_ids_then_returns_invalidToolCall() async {
        let dataSource = MockProductVariationsDataSource()
        let tool = ProductVariationsUpdateTool.make(dataSource: dataSource)

        let result = await tool.executor(#"{"product_id": 1, "id": 2}"#, NoopWCRESTClient())

        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(dataSource.updatedVariationID == nil)
    }
}

@MainActor
final class MockProductVariationsDataSource: AssistantProductVariationsDataSourceProtocol {
    var variationResult: Result<ProductVariation, Error> = .failure(TestVariationError.boom)
    var bulkResult = Result<BulkWriteResult, Error>.success(BulkWriteResult(updatedIDs: [], failedItems: []))
    private(set) var updatedProductID: Int64?
    private(set) var updatedVariationID: Int64?
    private(set) var updatedVariationPatch: ProductVariationUpdatePatch?
    private(set) var bulkProductID: Int64?
    private(set) var bulkPatches: [ProductVariationBatchPatch]?

    func updateVariation(productID: Int64,
                         variationID: Int64,
                         patch: ProductVariationUpdatePatch) async -> Result<ProductVariation, Error> {
        updatedProductID = productID
        updatedVariationID = variationID
        updatedVariationPatch = patch
        return variationResult
    }

    func bulkUpdateVariations(productID: Int64,
                              patches: [ProductVariationBatchPatch]) async -> Result<BulkWriteResult, Error> {
        bulkProductID = productID
        bulkPatches = patches
        return bulkResult
    }
}

private func makeVariation(id: Int64, parentID: Int64) -> ProductVariation {
    ProductVariation.fake().copy(siteID: 123,
                                 productID: parentID,
                                 productVariationID: id,
                                 status: .published,
                                 sku: "VAR-\(id)",
                                 price: "9.99",
                                 stockStatus: .inStock)
}

private enum TestVariationError: Error {
    case boom
}
