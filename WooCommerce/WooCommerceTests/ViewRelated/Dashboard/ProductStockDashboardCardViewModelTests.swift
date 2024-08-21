import XCTest
import Yosemite
import enum Networking.DotcomError
import enum Networking.NetworkError
@testable import WooCommerce

final class ProductStockDashboardCardViewModelTests: XCTestCase {

    @MainActor
    func test_initial_stock_type_is_low_stock() {
        // Given
        let viewModel = ProductStockDashboardCardViewModel(siteID: 123)

        // Then
        XCTAssertEqual(viewModel.selectedStockType, .lowStock)
    }

    @MainActor
    func test_updateStockType_updates_selected_stock_type() {
        // Given
        let viewModel = ProductStockDashboardCardViewModel(siteID: 123)

        // When
        viewModel.updateStockType(.outOfStock)

        // Then
        XCTAssertEqual(viewModel.selectedStockType, .outOfStock)
    }

    @MainActor
    func test_reloadData_fetches_stock_and_reports_for_appropriate_product_types() async {
        // Given
        let siteID: Int64 = 123
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = ProductStockDashboardCardViewModel(siteID: siteID, stores: stores)

        let product = ProductStock.fake().copy(siteID: siteID, productID: 32)
        let variation = ProductStock.fake().copy(siteID: siteID, productID: 44, parentID: 40)

        let thumbnailURL = "https://example.com/image.jpg"
        let productReport = ProductReport.fake().copy(productID: product.productID,
                                                      name: "Steamed bun",
                                                      imageURL: URL(string: thumbnailURL),
                                                      itemsSold: 10,
                                                      stockQuantity: 4)
        let variationReport = ProductReport.fake().copy(productID: variation.parentID,
                                                        variationID: variation.productID,
                                                        name: "Pizza - Large, Seafood, Spicy",
                                                        imageURL: nil,
                                                        itemsSold: 8,
                                                        stockQuantity: 3)
        XCTAssertTrue(viewModel.reports.isEmpty)

        // When
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .fetchStockReport(_, _, _, _, _, completion):
                completion(.success([product, variation]))
            case let .fetchProductReports(_, productIDs, _, _, _, _, _, _, _, completion):
                XCTAssertEqual(productIDs, [product.productID])
                completion(.success([productReport]))
            case let .fetchVariationReports(_, productIDs, variationIDs, _, _, _, _, _, _, _, completion):
                XCTAssertEqual(productIDs, [variation.parentID])
                XCTAssertEqual(variationIDs, [variation.productID])
                completion(.success([variationReport]))
            default:
                break
            }
        }
        await viewModel.reloadData()

        // Then
        XCTAssertEqual(viewModel.reports, [variationReport, productReport])
    }

    @MainActor
    func test_reloadData_updates_missing_parent_ids_for_variation_reports() async {
        // Given
        let siteID: Int64 = 123
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = ProductStockDashboardCardViewModel(siteID: siteID, stores: stores)

        let variation = ProductStock.fake().copy(siteID: siteID, productID: 44, parentID: 40)

        let thumbnailURL = "https://example.com/image.jpg"
        let variationReport = ProductReport.fake().copy(productID: 0, // missing product ID happens to some stores
                                                        variationID: variation.productID,
                                                        name: "Pizza - Large, Seafood, Spicy",
                                                        imageURL: nil,
                                                        itemsSold: 8,
                                                        stockQuantity: 3)
        XCTAssertTrue(viewModel.reports.isEmpty)

        // When
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .fetchStockReport(_, _, _, _, _, completion):
                completion(.success([variation]))
            case let .fetchVariationReports(_, productIDs, variationIDs, _, _, _, _, _, _, _, completion):
                XCTAssertEqual(productIDs, [variation.parentID])
                XCTAssertEqual(variationIDs, [variation.productID])
                completion(.success([variationReport]))
            default:
                break
            }
        }
        await viewModel.reloadData()

        // Then
        XCTAssertEqual(viewModel.reports, [variationReport.copy(productID: variation.parentID)])
    }

    @MainActor
    func test_reloadData_relays_error_when_one_of_the_requests_fail() async {
        // Given
        let siteID: Int64 = 123
        let productID: Int64 = siteID
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = ProductStockDashboardCardViewModel(siteID: siteID, stores: stores)

        let stock = ProductStock.fake().copy(siteID: siteID,
                                             productID: productID)
        let productReportError = NSError(domain: "test", code: 500)
        XCTAssertNil(viewModel.syncingError)

        // When
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .fetchStockReport(_, _, _, _, _, completion):
                completion(.success([stock]))
            case let .fetchProductReports(_, _, _, _, _, _, _, _, _, completion):
                completion(.failure(productReportError))
            default:
                break
            }
        }
        await viewModel.reloadData()

        // Then
        XCTAssertEqual(viewModel.syncingError as? NSError, productReportError)
    }

    @MainActor
    func test_analyticsEnabled_is_updated_correctly_when_sync_stats_failed_with_noRestRoute_error() async {
        // Given
        let siteID: Int64 = 123
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = ProductStockDashboardCardViewModel(siteID: siteID, stores: stores)
        XCTAssertTrue(viewModel.analyticsEnabled) // Initial value

        // When
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .fetchStockReport(_, _, _, _, _, completion):
                completion(.failure(DotcomError.noRestRoute))
            default:
                break
            }
        }
        await viewModel.reloadData()


        // Then
        XCTAssertFalse(viewModel.analyticsEnabled)
    }

    @MainActor
    func test_analyticsEnabled_is_updated_correctly_when_sync_stats_failed_with_notFound_error() async {
        // Given
        let siteID: Int64 = 123
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = ProductStockDashboardCardViewModel(siteID: siteID, stores: stores)
        XCTAssertTrue(viewModel.analyticsEnabled) // Initial value

        // When
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .fetchStockReport(_, _, _, _, _, completion):
                completion(.failure(NetworkError.notFound(response: nil)))
            default:
                break
            }
        }
        await viewModel.reloadData()


        // Then
        XCTAssertFalse(viewModel.analyticsEnabled)
    }
}
