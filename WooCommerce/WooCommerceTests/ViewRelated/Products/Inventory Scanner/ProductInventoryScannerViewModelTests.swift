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

    // MARK: - `searchProductBySKU`

    func test_searchProductBySKU_returns_previously_scanned_product() async throws {
        // Given
        let matchedProduct = Product.fake().copy(name: "Woo", sku: "122")
        let viewModel = ProductInventoryScannerViewModel(siteID: siteID,
                                                         // An existing product whose SKU matches the barcode.
                                                         results: [.matched(product: EditableProductModel(product: matchedProduct))],
                                                         stores: stores)
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            XCTFail("Unexpected action dispatched: \(action)")
        }

        // When
        let result = await viewModel.searchProductBySKU(barcode: "122")

        // Then
        XCTAssertTrue(result.isSuccess)
    }

    func test_searchProductBySKU_returns_success_when_ProductAction_returns_a_product() async throws {
        // Given
        let matchedProduct = Product.fake().copy(name: "Woo")
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            guard case let .findProductBySKU(_, _, completion) = action else {
                return XCTFail("Unexpected action dispatched: \(action)")
            }
            completion(.success(matchedProduct))
        }
        let viewModel = ProductInventoryScannerViewModel(siteID: siteID,
                                                         // An existing product whose SKU doesn't match the barcode.
                                                         results: [.matched(product: EditableProductModel(product: .fake()))],
                                                         stores: stores)

        // When
        let result = await viewModel.searchProductBySKU(barcode: "122")

        // Then
        XCTAssertTrue(result.isSuccess)
    }

    func test_searchProductBySKU_returns_failure_when_ProductAction_returns_error() async throws {
        // Given
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            guard case let .findProductBySKU(_, _, completion) = action else {
                return XCTFail("Unexpected action dispatched: \(action)")
            }
            completion(.failure(ProductInventoryScannerError.selfDeallocated))
        }
        let viewModel = ProductInventoryScannerViewModel(siteID: siteID, stores: stores)

        // When
        let result = await viewModel.searchProductBySKU(barcode: "122")

        // Then
        let error = try XCTUnwrap(result.failure)
        XCTAssertEqual(error as? ProductInventoryScannerError, .selfDeallocated)
    }

    // MARK: - `results`

    func test_matched_product_from_searchProductBySKU_is_inserted_to_results_with_incremented_stock_quantity() async throws {
        // Given
        let matchedProduct = Product.fake().copy(name: "Woo", sku: "122", stockQuantity: 12.6)
        let viewModel = ProductInventoryScannerViewModel(siteID: siteID,
                                                         // An existing product whose SKU matches the barcode.
                                                         results: [.matched(product: EditableProductModel(product: matchedProduct))],
                                                         stores: stores)
        XCTAssertEqual(viewModel.results, [.matched(product: EditableProductModel(product: matchedProduct))])

        // When
        let result = await viewModel.searchProductBySKU(barcode: "122")

        // Then
        XCTAssertEqual(viewModel.results, [.matched(product: EditableProductModel(product: matchedProduct))])
        guard let lastResult = viewModel.results.last,
              case let .matched(productFromResult) = lastResult else {
            return XCTFail("Last scanner result is not a success case.")
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
                                                         results: [.matched(product: EditableProductModel(product: .fake()))],
                                                         stores: stores)
        XCTAssertEqual(viewModel.results, [.matched(product: EditableProductModel(product: .fake()))])

        // When
        let result = await viewModel.searchProductBySKU(barcode: "122")

        // Then
        XCTAssertEqual(viewModel.results, [.noMatch(sku: "122"), .matched(product: EditableProductModel(product: .fake()))])
    }
}
