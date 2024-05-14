import XCTest
@testable import WooCommerce
import Yosemite
import protocol WooFoundation.Analytics

final class AnalyticsHubCustomizeViewModelTests: XCTestCase {

    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: Analytics!

    override func setUp() {
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
    }

    func test_it_inits_with_expected_properties() {
        // Given
        let revenueCard = AnalyticsCard(type: .revenue, enabled: true)
        let ordersCard = AnalyticsCard(type: .orders, enabled: false)
        let sessionsCard = AnalyticsCard(type: .sessions, enabled: true)
        let vm = AnalyticsHubCustomizeViewModel(allCards: [revenueCard, ordersCard, sessionsCard], inactiveCards: [sessionsCard])

        // Then
        assertEqual([revenueCard, ordersCard], vm.allCards)
        assertEqual([revenueCard], vm.selectedCards)
        XCTAssertFalse(vm.hasChanges)
    }

    func test_it_groups_all_selected_cards_at_top_of_allCards_list_in_original_order() {
        // Given
        let revenueCard = AnalyticsCard(type: .revenue, enabled: false)
        let ordersCard = AnalyticsCard(type: .orders, enabled: true)
        let productsCard = AnalyticsCard(type: .products, enabled: true)
        let vm = AnalyticsHubCustomizeViewModel(allCards: [revenueCard, ordersCard, productsCard])

        // Then
        assertEqual([ordersCard, productsCard, revenueCard], vm.allCards)
    }

    func test_hasChanges_is_true_when_card_order_changes() {
        // Given
        let revenueCard = AnalyticsCard(type: .revenue, enabled: false)
        let ordersCard = AnalyticsCard(type: .orders, enabled: false)
        let vm = AnalyticsHubCustomizeViewModel(allCards: [revenueCard, ordersCard])

        // When
        vm.allCards = [ordersCard, revenueCard]

        // Then
        XCTAssertTrue(vm.hasChanges)
    }

    func test_hasChanges_is_true_when_selection_changes() {
        // Given
        let revenueCard = AnalyticsCard(type: .revenue, enabled: false)
        let ordersCard = AnalyticsCard(type: .orders, enabled: true)
        let vm = AnalyticsHubCustomizeViewModel(allCards: [revenueCard, ordersCard])

        // When
        vm.selectedCards = [revenueCard, ordersCard]

        // Then
        XCTAssertTrue(vm.hasChanges)
    }

    func test_saveChanges_returns_updated_array_of_cards() {
        // Given
        let revenueCard = AnalyticsCard(type: .revenue, enabled: false)
        let ordersCard = AnalyticsCard(type: .orders, enabled: true)
        let productsCard = AnalyticsCard(type: .products, enabled: true)
        let sessionsCard = AnalyticsCard(type: .sessions, enabled: true)

        // When
        let actualCards = waitFor { promise in
            let vm = AnalyticsHubCustomizeViewModel(allCards: [revenueCard, ordersCard, productsCard],
                                                    inactiveCards: [sessionsCard],
                                                    analytics: self.analytics) { updatedCards in
                promise(updatedCards)
            }

            vm.allCards = [ordersCard, revenueCard, productsCard]
            vm.selectedCards = [revenueCard, ordersCard]
            vm.saveChanges()
        }

        // Then
        let expectedCards = [ordersCard, revenueCard.copy(enabled: true), productsCard.copy(enabled: false), sessionsCard]
        assertEqual(expectedCards, actualCards)
    }

    func test_saveChanges_tracks_expected_event() throws {
        // Given
        let revenueCard = AnalyticsCard(type: .revenue, enabled: true)
        let ordersCard = AnalyticsCard(type: .orders, enabled: true)
        let productsCard = AnalyticsCard(type: .products, enabled: false)
        let sessionsCard = AnalyticsCard(type: .sessions, enabled: true)
        let vm = AnalyticsHubCustomizeViewModel(allCards: [revenueCard, ordersCard, productsCard, sessionsCard],
                                                inactiveCards: [sessionsCard],
                                                analytics: analytics)

        // When
        vm.saveChanges()

        // Then
        XCTAssert(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.analyticsHubSettingsSaved.rawValue))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties.last)
        assertEqual("revenue,orders", eventProperties["enabled_cards"] as? String)
        assertEqual("products", eventProperties["disabled_cards"] as? String)
    }

}
