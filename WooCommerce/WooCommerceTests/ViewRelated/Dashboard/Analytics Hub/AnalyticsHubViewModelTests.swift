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
        XCTAssertEqual(vm.revenueCard?.isRedacted, false)
        XCTAssertEqual(vm.ordersCard?.isRedacted, false)
        XCTAssertEqual(vm.productCard?.isRedacted, false)

        XCTAssertEqual(vm.revenueCard?.leadingValue, "$62")
        XCTAssertEqual(vm.ordersCard?.leadingValue, "15")
        XCTAssertEqual(vm.productCard?.itemsSold, "5")
    }

    func test_cards_viewmodels_nil_after_getting_error_from_network() async {
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
        XCTAssertNil(vm.revenueCard)
        XCTAssertNil(vm.ordersCard)
        XCTAssertNil(vm.productCard)
    }

    func test_cards_viewmodels_redacted_while_updating_from_network() async {
        // Given
        let vm = AnalyticsHubViewModel(siteID: 123, statsTimeRange: .thisMonth, stores: stores)
        let stats = OrderStatsV4.fake().copy(totals: .fake().copy(totalOrders: 15, totalItemsSold: 5, grossRevenue: 62))
        var loadingRevenueCard: AnalyticsReportCardViewModel?
        var loadingOrdersCard: AnalyticsReportCardViewModel?
        var loadingProductsCard: AnalyticsProductCardViewModel?
        stores.whenReceivingAction(ofType: StatsActionV4.self) { action in
            if case let .retrieveCustomStats(_, _, _, _, _, _, completion) = action {
                loadingRevenueCard = vm.revenueCard
                loadingOrdersCard = vm.ordersCard
                loadingProductsCard = vm.productCard
                completion(.success(stats))
            }
        }

        // When
        await vm.updateData()

        // Then
        XCTAssertEqual(loadingRevenueCard?.isRedacted, true)
        XCTAssertEqual(loadingOrdersCard?.isRedacted, true)
        XCTAssertEqual(loadingProductsCard?.isRedacted, true)
    }
}
