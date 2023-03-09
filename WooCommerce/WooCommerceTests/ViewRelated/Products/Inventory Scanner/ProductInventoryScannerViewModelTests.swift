import Combine
import TestKit
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
        try await viewModel.searchProductBySKU(barcode: "122")

        // Then
        XCTAssertEqual(viewModel.results, [.matched(product: EditableProductModel(product: matchedProduct), initialStockQuantity: 13.6),
                                           .noMatch(sku: "566")])
        guard let result = viewModel.results.first,
              case let .matched(productFromResult, _) = result else {
            return XCTFail("The first scanner result is not a success case.")
        }
        XCTAssertEqual(productFromResult.stockQuantity, 13.6)
    }

    func test_noMatch_result_from_searchProductBySKU_is_inserted_to_results() async throws {
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

        await assertThrowsError({
            // When
            try await viewModel.searchProductBySKU(barcode: "122")
        }) { error in
            // Then
            (error as? ProductInventoryScannerError) == .selfDeallocated
        }

        // Then
        XCTAssertEqual(viewModel.results, [.noMatch(sku: "122"), .matched(product: EditableProductModel(product: .fake()), initialStockQuantity: 0)])
    }

    // MARK: - `saveResults`

    func test_saveResults_without_products_does_not_dispatch_ProductAction() async throws {
        // Given
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            XCTFail("Unexpected action dispatched: \(action)")
        }
        let viewModel = ProductInventoryScannerViewModel(siteID: siteID,
                                                         results: [.noMatch(sku: "566")],
                                                         stores: stores)

        // When
        try await viewModel.saveResults()

        // Then the `XCTFail` should not be triggered
    }

    // MARK: - `updateInventory`

    func test_updateInventory_moves_existing_result_to_the_first_with_updated_inventory() async throws {
        // Given
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            XCTFail("Unexpected action dispatched: \(action)")
        }
        let product = EditableProductModel(product: .fake().copy(sku: "",
                                                                 manageStock: false,
                                                                 stockQuantity: 12,
                                                                 stockStatusKey: ProductStockStatus.outOfStock.rawValue,
                                                                 backordersKey: ProductBackordersSetting.notAllowed.rawValue,
                                                                 soldIndividually: false))
        let viewModel = ProductInventoryScannerViewModel(siteID: siteID,
                                                         results: [.noMatch(sku: "color-pencil"),
                                                                   .matched(product: product, initialStockQuantity: 0)],
                                                         stores: stores)

        // When
        viewModel.updateInventory(for: product, inventory: .init(sku: "test",
                                                                 manageStock: true,
                                                                 soldIndividually: true,
                                                                 stockQuantity: 62,
                                                                 backordersSetting: .allowed,
                                                                 stockStatus: .insufficientStock),
                                  initialQuantity: 0)

        // Then
        XCTAssertEqual(viewModel.results, [.matched(product: product, initialStockQuantity: 0),
                                           .noMatch(sku: "color-pencil")])
        guard let result = viewModel.results.first,
              case let .matched(productFromResult, _) = result else {
            return XCTFail("The first scanner result is not a success case.")
        }
        XCTAssertEqual(productFromResult.sku, "test")
        XCTAssertEqual(productFromResult.manageStock, true)
        XCTAssertEqual(productFromResult.soldIndividually, true)
        XCTAssertEqual(productFromResult.stockQuantity, 62)
        XCTAssertEqual(productFromResult.backordersSetting, .allowed)
        XCTAssertEqual(productFromResult.stockStatus, .insufficientStock)
    }

    // MARK: - `saveResults`

    func test_saveResults_with_products_returns_success_from_ProductAction_updateProducts() async throws {
        // Given
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            guard case let .updateProducts(_, _, completion) = action else {
                return XCTFail("Unexpected action dispatched: \(action)")
            }
            completion(.success([]))
        }
        let viewModel = ProductInventoryScannerViewModel(siteID: siteID,
                                                         results: [.matched(product: EditableProductModel(product: .fake()), initialStockQuantity: 0)],
                                                         stores: stores)

        // When
        try await viewModel.saveResults()

        // Then the `XCTFail` should not be triggered
    }

    func test_saveResults_with_products_returns_error_from_ProductAction_updateProducts() async throws {
        // Given
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            guard case let .updateProducts(_, _, completion) = action else {
                return XCTFail("Unexpected action dispatched: \(action)")
            }
            completion(.failure(.unexpected))
        }
        let viewModel = ProductInventoryScannerViewModel(siteID: siteID,
                                                         results: [.matched(product: EditableProductModel(product: .fake()), initialStockQuantity: 0)],
                                                         stores: stores)

        await assertThrowsError({
            // When
            try await viewModel.saveResults()
        }) { error in
            // Then
            (error as? ProductUpdateError) == .unexpected
        }
    }
}
