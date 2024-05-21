import XCTest
import Yosemite
@testable import WooCommerce

final class ProductStockDashboardCardViewModelTests: XCTestCase {

    func test_initial_stock_type_is_low_stock() {
        // Given
        let viewModel = ProductStockDashboardCardViewModel(siteID: 123)

        // Then
        XCTAssertEqual(viewModel.selectedStockType, .lowStock)
    }

    func test_updateStockType_updates_selected_stock_type() {
        // Given
        let viewModel = ProductStockDashboardCardViewModel(siteID: 123)

        // When
        viewModel.updateStockType(.outOfStock)

        // Then
        XCTAssertEqual(viewModel.selectedStockType, .outOfStock)
    }

    @MainActor
    func test_reloadData_updates_stock_correctly() async {
        // Given
        let siteID: Int64 = 123
        let productID: Int64 = siteID
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = ProductStockDashboardCardViewModel(siteID: siteID, stores: stores)

        let stock = ProductStock.fake().copy(siteID: siteID,
                                             productID: productID,
                                             name: "Steamed bun",
                                             sku: "1353",
                                             manageStock: true,
                                             stockQuantity: 4,
                                             stockStatusKey: "instock")
        let segment = ProductReportSegment.fake().copy(productID: 123, productName: "Steamed bun", subtotals: .fake().copy(itemsSold: 10))
        let thumbnailURL = "https://example.com/image.jpg"
        XCTAssertTrue(viewModel.stock.isEmpty)

        // When
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .fetchStockReport(_, _, _, _, _, _, completion):
                completion(.success([stock]))
            case let .fetchProductReports(_, _, _, _, _, _, _, _, _, completion):
                completion(.success([segment]))
            case let .retrieveProducts(_, _, _, _, onCompletion):
                let image = ProductImage.fake().copy(src: thumbnailURL)
                let product = Product.fake().copy(productID: productID, images: [image])
                onCompletion(.success(([product], false)))
            default:
                break
            }
        }
        await viewModel.reloadData()

        // Then
        let expectedItem = ProductStockDashboardCardViewModel.StockItem(
            productID: productID,
            productName: "Steamed bun",
            stockQuantity: 4,
            thumbnailURL: URL(string: thumbnailURL),
            itemsSoldLast30Days: segment.subtotals.itemsSold
        )
        XCTAssertEqual(viewModel.stock, [expectedItem])
    }

    @MainActor
    func test_reloadData_reuse_in_memory_data_for_previously_fetched_items() async {
        // Given
        let siteID: Int64 = 123
        let productID: Int64 = siteID
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = ProductStockDashboardCardViewModel(siteID: siteID, stores: stores)

        let stock = ProductStock.fake().copy(siteID: siteID,
                                             productID: productID,
                                             name: "Steamed bun",
                                             sku: "1353",
                                             manageStock: true,
                                             stockQuantity: 4,
                                             stockStatusKey: "instock")
        let segment = ProductReportSegment.fake().copy(productID: 123, productName: "Steamed bun", subtotals: .fake().copy(itemsSold: 10))
        let thumbnailURL = "https://example.com/image.jpg"

        var fetchStockRequestCount = 0
        var fetchProductReportRequestCount = 0
        var retrieveProductsRequestCount = 0

        // When
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .fetchStockReport(_, _, _, _, _, _, completion):
                fetchStockRequestCount += 1
                completion(.success([stock]))
            case let .fetchProductReports(_, _, _, _, _, _, _, _, _, completion):
                fetchProductReportRequestCount += 1
                completion(.success([segment]))
            case let .retrieveProducts(_, _, _, _, onCompletion):
                retrieveProductsRequestCount += 1
                let image = ProductImage.fake().copy(src: thumbnailURL)
                let product = Product.fake().copy(productID: productID, images: [image])
                onCompletion(.success(([product], false)))
            default:
                break
            }
        }
        await viewModel.reloadData()

        // Then
        XCTAssertEqual(fetchStockRequestCount, 1)
        XCTAssertEqual(fetchProductReportRequestCount, 1)
        XCTAssertEqual(retrieveProductsRequestCount, 1)

        // When
        await viewModel.reloadData() // request again, e.g. when pulling-to-refresh.

        // Then
        XCTAssertEqual(fetchStockRequestCount, 2)
        XCTAssertEqual(fetchProductReportRequestCount, 1)
        XCTAssertEqual(retrieveProductsRequestCount, 1)
    }

    @MainActor
    func test_reloadData_relays_error_when_one_of_the_requests_fail() async {
        // Given
        let siteID: Int64 = 123
        let productID: Int64 = siteID
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = ProductStockDashboardCardViewModel(siteID: siteID, stores: stores)

        let stock = ProductStock.fake().copy(siteID: siteID,
                                             productID: productID,
                                             name: "Steamed bun",
                                             sku: "1353",
                                             manageStock: true,
                                             stockQuantity: 4,
                                             stockStatusKey: "instock")
        let thumbnailURL = "https://example.com/image.jpg"
        let productReportError = NSError(domain: "test", code: 500)
        XCTAssertNil(viewModel.syncingError)

        // When
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .fetchStockReport(_, _, _, _, _, _, completion):
                completion(.success([stock]))
            case let .fetchProductReports(_, _, _, _, _, _, _, _, _, completion):
                completion(.failure(productReportError))
            case let .retrieveProducts(_, _, _, _, onCompletion):
                let image = ProductImage.fake().copy(src: thumbnailURL)
                let product = Product.fake().copy(productID: productID, images: [image])
                onCompletion(.success(([product], false)))
            default:
                break
            }
        }
        await viewModel.reloadData()

        // Then
        XCTAssertEqual(viewModel.syncingError as? NSError, productReportError)
    }
}
