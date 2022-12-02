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

        stores.whenReceivingAction(ofType: StatsActionV4.self) { action in
            switch action {
            case let .retrieveCustomStats(_, _, _, _, _, _, completion):
                let stats = OrderStatsV4.fake().copy(totals: .fake().copy(totalOrders: 15, totalItemsSold: 5, grossRevenue: 62))
                completion(.success(stats))
            case let .retrieveTopEarnerStats(_, _, _, _, _, _, _, completion):
                let topEarners = TopEarnerStats.fake().copy(items: [.fake()])
                completion(.success(topEarners))
            default:
                break
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
        XCTAssertEqual(vm.productCard.itemsSoldData.count, 1)
    }

    func test_cards_viewmodels_show_sync_error_after_getting_error_from_network() async {
        // Given
        let vm = AnalyticsHubViewModel(siteID: 123, statsTimeRange: .thisMonth, stores: stores)
        stores.whenReceivingAction(ofType: StatsActionV4.self) { action in
            switch action {
            case let .retrieveCustomStats(_, _, _, _, _, _, completion):
                completion(.failure(NSError(domain: "Test", code: 1)))
            case let .retrieveTopEarnerStats(_, _, _, _, _, _, _, completion):
                completion(.failure(NSError(domain: "Test", code: 1)))
            default:
                break
            }
            switch action {
            case let .retrieveCustomStats(_, _, _, _, _, _, completion):
                completion(.failure(NSError(domain: "Test", code: 1)))
            case let .retrieveTopEarnerStats(_, _, _, _, _, _, _, completion):
                completion(.failure(NSError(domain: "Test", code: 1)))
            default:
                break
            }
        }

        // When
        await vm.updateData()

        // Then
        XCTAssertTrue(vm.revenueCard.showSyncError)
        XCTAssertTrue(vm.ordersCard.showSyncError)
        XCTAssertTrue(vm.productCard.showStatsError)
        XCTAssertTrue(vm.productCard.showItemsSoldError)
    }

    func test_cards_viewmodels_redacted_while_updating_from_network() async {
        // Given
        let vm = AnalyticsHubViewModel(siteID: 123, statsTimeRange: .thisMonth, stores: stores)
        var loadingRevenueCard: AnalyticsReportCardViewModel?
        var loadingOrdersCard: AnalyticsReportCardViewModel?
        var loadingProductsCard: AnalyticsProductCardViewModel?
        stores.whenReceivingAction(ofType: StatsActionV4.self) { action in
            switch action {
            case let .retrieveCustomStats(_, _, _, _, _, _, completion):
                let stats = OrderStatsV4.fake().copy(totals: .fake().copy(totalOrders: 15, totalItemsSold: 5, grossRevenue: 62))
                loadingRevenueCard = vm.revenueCard
                loadingOrdersCard = vm.ordersCard
                loadingProductsCard = vm.productCard
                completion(.success(stats))
            case let .retrieveTopEarnerStats(_, _, _, _, _, _, _, completion):
                let topEarners = TopEarnerStats.fake().copy(items: [.fake()])
                completion(.success(topEarners))
            default:
                break
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
