import Foundation
import Fakes
import Testing
import Yosemite
@testable import WooAIAssistant

@MainActor
struct ProductsUpdateToolTests {
    @Test
    func test_productsUpdate_when_name_set_then_calls_dataSource() async throws {
        let dataSource = MockProductsDataSource()
        dataSource.productResult = .success(makeProduct(id: 12, name: "Wool Sweater"))
        let tool = ProductsUpdateTool.make(dataSource: dataSource)

        let result = await tool.executor(#"{"id": 12, "name": "Wool Sweater"}"#, NoopWCRESTClient())

        guard case .success = result else {
            Issue.record("expected success, got \(result)")
            return
        }
        #expect(dataSource.updatedProductID == 12)
        #expect(dataSource.updatedProductPatch?.name == "Wool Sweater")
        #expect(dataSource.updatedProductPatch?.regularPrice == nil)
    }

    @Test
    func test_productsUpdate_when_field_outside_allowlist_then_not_passed_to_dataSource() async throws {
        let dataSource = MockProductsDataSource()
        dataSource.productResult = .success(makeProduct(id: 12, name: "X"))
        let tool = ProductsUpdateTool.make(dataSource: dataSource)

        let arguments = #"""
        {"id": 12, "name": "X", "categories": [{"id": 99}], "tags": ["spring"]}
        """#
        let result = await tool.executor(arguments, NoopWCRESTClient())

        guard case .success = result else {
            Issue.record("expected success, got \(result)")
            return
        }
        #expect(dataSource.updatedProductPatch?.name == "X")
        #expect(dataSource.updatedProductPatch?.regularPrice == nil)
    }

    @Test
    func test_productsUpdate_when_stock_quantity_set_then_patch_carries_stock_quantity() async throws {
        let dataSource = MockProductsDataSource()
        dataSource.productResult = .success(makeProduct(id: 12))
        let tool = ProductsUpdateTool.make(dataSource: dataSource)

        let result = await tool.executor(#"{"id": 12, "stock_quantity": 5}"#, NoopWCRESTClient())

        guard case .success = result else {
            Issue.record("expected success, got \(result)")
            return
        }
        #expect(dataSource.updatedProductPatch?.stockQuantity == 5)
    }

    @Test
    func test_productsUpdate_when_variable_product_price_rejected_then_returns_invalidToolCall() async throws {
        let dataSource = MockProductsDataSource()
        dataSource.productResult = .failure(AssistantDataSourceError.variableProductPrice(productID: 12))
        let tool = ProductsUpdateTool.make(dataSource: dataSource)

        let result = await tool.executor(#"{"id": 12, "regular_price": "19.99"}"#, NoopWCRESTClient())

        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(failed.reason.contains("product_variations_update"))
    }

    @Test
    func test_productsUpdate_when_only_id_provided_then_returns_invalidToolCall() async {
        let dataSource = MockProductsDataSource()
        let tool = ProductsUpdateTool.make(dataSource: dataSource)

        let result = await tool.executor(#"{"id": 12}"#, NoopWCRESTClient())

        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(dataSource.updatedProductID == nil)
    }

    @Test
    func test_productsUpdate_when_status_outside_allowlist_then_returns_invalidToolCall() async {
        let dataSource = MockProductsDataSource()
        let tool = ProductsUpdateTool.make(dataSource: dataSource)

        let result = await tool.executor(#"{"id": 12, "status": "archived"}"#, NoopWCRESTClient())

        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(dataSource.updatedProductID == nil)
    }
}

@MainActor
final class MockProductsDataSource: AssistantProductsDataSourceProtocol {
    var productResult: Result<Product, Error> = .failure(SampleError.boom)
    var bulkResult = Result<BulkWriteResult, Error>.success(BulkWriteResult(updatedIDs: [], failedItems: []))
    private(set) var updatedProductID: Int64?
    private(set) var updatedProductPatch: ProductUpdatePatch?
    private(set) var bulkIDs: [Int64]?
    private(set) var bulkPatch: ProductUpdatePatch?

    func updateProduct(id: Int64, patch: ProductUpdatePatch) async -> Result<Product, Error> {
        updatedProductID = id
        updatedProductPatch = patch
        return productResult
    }

    func bulkUpdateProducts(ids: [Int64], patch: ProductUpdatePatch) async -> Result<BulkWriteResult, Error> {
        bulkIDs = ids
        bulkPatch = patch
        return bulkResult
    }
}

private func makeProduct(id: Int64, name: String = "Item") -> Product {
    Product.fake().copy(siteID: 123,
                        productID: id,
                        name: name,
                        productTypeKey: ProductType.simple.rawValue,
                        statusKey: "publish")
}

private enum SampleError: Error {
    case boom
}
