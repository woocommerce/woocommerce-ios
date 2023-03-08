import Combine
import XCTest
import Yosemite
@testable import WooCommerce

@MainActor
final class ProductInventoryScannerViewModelTests: XCTestCase {
    private var stores: MockStoresManager!
    private var subscriptions: Set<AnyCancellable> = []
    private let siteID: Int64 = 134

    override func setUp() {
        super.setUp()
        stores = MockStoresManager(sessionManager: SessionManager.makeForTesting())
    }

    override func tearDown() {
        stores = nil
        super.tearDown()
    }

    // MARK: - `results`

    func test_previously_scanned_product_from_searchProductBySKU_is_inserted_to_results_with_incremented_stock_quantity() async throws {
        // Given
        let matchedProduct = Product.fake().copy(name: "Woo", sku: "122", stockQuantity: 12.6)
        let viewModel = ProductInventoryScannerViewModel(siteID: siteID,
                                                         results: [
                                                            .noMatch(sku: "566"),
                                                            // An existing product whose SKU matches the barcode.
                                                            .matched(product: EditableProductModel(product: matchedProduct),
                                                                     initialStockQuantity: 12.6)],
                                                         stores: stores)
        XCTAssertEqual(viewModel.results, [.noMatch(sku: "566"),
                                           .matched(product: EditableProductModel(product: matchedProduct), initialStockQuantity: 12.6)])

        // When
        let _ = await viewModel.searchProductBySKU(barcode: "122")

        // Then
        XCTAssertEqual(viewModel.results, [.matched(product: EditableProductModel(product: matchedProduct), initialStockQuantity: 13.6),
                                           .noMatch(sku: "566")])
        guard let result = viewModel.results.first,
              case let .matched(productFromResult, _) = result else {
            return XCTFail("The first scanner result is not a success case.")
        }
        XCTAssertEqual(productFromResult.stockQuantity, 13.6)
    }

    func test_no_matched_product_from_searchProductBySKU_is_inserted_to_results() async throws {
        // Given
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            guard case let .findProductBySKU(_, _, completion) = action else {
                return XCTFail("Unexpected action dispatched: \(action)")
            }
            completion(.failure(ProductInventoryScannerError.selfDeallocated))
        }
        let viewModel = ProductInventoryScannerViewModel(siteID: siteID,
                                                         // An existing product whose SKU doesn't match the barcode.
                                                         results: [.matched(product: EditableProductModel(product: .fake()), initialStockQuantity: 0)],
                                                         stores: stores)
        XCTAssertEqual(viewModel.results, [.matched(product: EditableProductModel(product: .fake()), initialStockQuantity: 0)])

        // When
        let _ = await viewModel.searchProductBySKU(barcode: "122")

        // Then
        XCTAssertEqual(viewModel.results, [.noMatch(sku: "122"), .matched(product: EditableProductModel(product: .fake()), initialStockQuantity: 0)])
    }
}
