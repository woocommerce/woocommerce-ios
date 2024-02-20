import XCTest
@testable import WooCommerce
import Yosemite

final class AnalyticsHubCustomizeViewModelTests: XCTestCase {

    func test_it_inits_with_expected_properties() {
        // Given
        let revenueCard = AnalyticsCard(type: .revenue, enabled: true)
        let ordersCard = AnalyticsCard(type: .orders, enabled: false)
        let vm = AnalyticsHubCustomizeViewModel(allCards: [revenueCard, ordersCard])

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

        // When
        let actualCards = waitFor { promise in
            let vm = AnalyticsHubCustomizeViewModel(allCards: [revenueCard, ordersCard, productsCard]) { updatedCards in
                promise(updatedCards)
            }

            vm.allCards = [ordersCard, revenueCard, productsCard]
            vm.selectedCards = [revenueCard, ordersCard]
            vm.saveChanges()
        }

        // Then
        let expectedCards = [AnalyticsCard(type: .orders, enabled: true),
                             AnalyticsCard(type: .revenue, enabled: true),
                             AnalyticsCard(type: .products, enabled: false)]
        assertEqual(expectedCards, actualCards)
    }

}
