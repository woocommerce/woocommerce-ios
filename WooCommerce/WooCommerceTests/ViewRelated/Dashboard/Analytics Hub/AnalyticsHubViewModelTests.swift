import XCTest
import Yosemite
@testable import WooCommerce

final class AnalyticsHubViewModelTests: XCTestCase {

    private var stores: MockStoresManager!

    override func setUp() {
        stores = MockStoresManager(sessionManager: .makeForTesting())
    }

    func test_cards_viewmodels_show_correct_data_after_updating_from_network() async {
        // Given
        let vm = AnalyticsHubViewModel(siteID: 123, statsTimeRange: .thisMonth, stores: stores)
        let stats = OrderStatsV4.fake().copy(totals: .fake().copy(totalOrders: 15, totalItemsSold: 5, grossRevenue: 62))
        stores.whenReceivingAction(ofType: StatsActionV4.self) { action in
            if case let .retrieveCustomStats(_, _, _, _, _, _, completion) = action {
                completion(.success(stats))
            }
        }

        // When
        await vm.updateData()

        // Then
        XCTAssertFalse(vm.revenueCard.isRedacted)
        XCTAssertFalse(vm.ordersCard.isRedacted)
        XCTAssertFalse(vm.productCard.isRedacted)

        XCTAssertEqual(vm.revenueCard.leadingValue, "$62")
        XCTAssertEqual(vm.ordersCard.leadingValue, "15")
        XCTAssertEqual(vm.productCard.itemsSold, "5")
    }

    func test_cards_viewmodels_show_empty_data_after_getting_error_from_network() async {
        // Given
        let vm = AnalyticsHubViewModel(siteID: 123, statsTimeRange: .thisMonth, stores: stores)
        stores.whenReceivingAction(ofType: StatsActionV4.self) { action in
            if case let .retrieveCustomStats(_, _, _, _, _, _, completion) = action {
                completion(.failure(NSError(domain: "Test", code: 1)))
            }
        }

        // When
        await vm.updateData()

        // Then
        XCTAssertFalse(vm.revenueCard.isRedacted)
        XCTAssertFalse(vm.ordersCard.isRedacted)
        XCTAssertFalse(vm.productCard.isRedacted)

        XCTAssertEqual(vm.revenueCard.leadingValue, "-")
        XCTAssertEqual(vm.ordersCard.leadingValue, "-")
        XCTAssertEqual(vm.productCard.itemsSold, "-")
    }
}
