import XCTest
@testable import WooCommerce

final class AnalyticsHubCustomizeViewModelTests: XCTestCase {

    func test_it_inits_with_expected_properties() {
        // Given
        let allCards = ["First", "Second"]
        let selectedCards = Set(["First"])
        let vm = AnalyticsHubCustomizeViewModel(allCards: allCards, selectedCards: selectedCards)

        // Then
        assertEqual(allCards, vm.allCards)
        assertEqual(selectedCards, vm.selectedCards)
        XCTAssertFalse(vm.hasChanges)
    }

    func test_it_groups_all_selected_cards_at_top_of_allCards_list_in_original_order() {
        // Given
        let vm = AnalyticsHubCustomizeViewModel(allCards: ["First", "Second", "Third"], selectedCards: ["Third", "Second"])

        // Then
        assertEqual(["Second", "Third", "First"], vm.allCards)
    }

    func test_hasChanges_is_true_when_card_order_changes() {
        // Given
        let vm = AnalyticsHubCustomizeViewModel(allCards: ["First", "Second"], selectedCards: [])

        // When
        vm.allCards = ["Second", "First"]

        // Then
        XCTAssertTrue(vm.hasChanges)
    }

    func test_hasChanges_is_true_when_selection_changes() {
        // Given
        let vm = AnalyticsHubCustomizeViewModel(allCards: ["First", "Second"], selectedCards: ["Second"])

        // When
        vm.selectedCards = ["First", "Second"]

        // Then
        XCTAssertTrue(vm.hasChanges)
    }

}
