import XCTest
@testable import WooCommerce
import Yosemite

final class DashboardCustomizationViewModelTests: XCTestCase {

    func test_it_inits_with_expected_properties() {
        // Given
        let onboarding = DashboardCard(type: .onboarding, isAvailable: true, enabled: false, status: .show)
        let stats = DashboardCard(type: .performance, isAvailable: true, enabled: true, status: .show)
        let blaze = DashboardCard(type: .blaze, isAvailable: true, enabled: false, status: .show)
        let vm = DashboardCustomizationViewModel(allCards: [onboarding, stats, blaze], inactiveCards: [blaze])

        // Then
        assertEqual([stats, onboarding], vm.allCards)
        assertEqual([stats], vm.selectedCards)
        XCTAssertFalse(vm.hasChanges)
    }

    func test_it_groups_all_selected_cards_at_top_of_allCards_list_in_original_order() {
        // Given
        let onboarding = DashboardCard(type: .onboarding, isAvailable: true, enabled: false, status: .show)
        let stats = DashboardCard(type: .performance, isAvailable: true, enabled: true, status: .show)
        let blaze = DashboardCard(type: .blaze, isAvailable: true, enabled: true, status: .show)
        let vm = DashboardCustomizationViewModel(allCards: [onboarding, stats, blaze])

        // Then
        assertEqual([stats, blaze, onboarding], vm.allCards)
    }

    func test_hasChanges_is_true_when_card_order_changes() {
        // Given
        let onboarding = DashboardCard(type: .onboarding, isAvailable: true, enabled: true, status: .show)
        let stats = DashboardCard(type: .performance, isAvailable: true, enabled: true, status: .show)
        let vm = DashboardCustomizationViewModel(allCards: [onboarding, stats])

        // When
        vm.allCards = [stats, onboarding]

        // Then
        XCTAssertTrue(vm.hasChanges)
    }

    func test_hasChanges_is_true_when_selection_changes() {
        // Given
        let onboarding = DashboardCard(type: .onboarding, isAvailable: true, enabled: false, status: .show)
        let stats = DashboardCard(type: .performance, isAvailable: true, enabled: true, status: .show)
        let vm = DashboardCustomizationViewModel(allCards: [onboarding, stats])

        // When
        vm.selectedCards = [onboarding, stats]

        // Then
        XCTAssertTrue(vm.hasChanges)
    }

    func test_saveChanges_returns_updated_array_of_cards() {
        // Given
        let onboarding = DashboardCard(type: .onboarding, isAvailable: true, enabled: true, status: .show)
        let stats = DashboardCard(type: .performance, isAvailable: true, enabled: false, status: .show)
        let blaze = DashboardCard(type: .blaze, isAvailable: true, enabled: false, status: .show)

        // When
        let actualCards = waitFor { promise in
            let vm = DashboardCustomizationViewModel(allCards: [onboarding, stats, blaze],
                                                    inactiveCards: [blaze]) { updatedCards in
                promise(updatedCards)
            }

            vm.allCards = [stats, onboarding]
            vm.selectedCards = [stats]
            vm.saveChanges()
        }

        // Then
        let expectedCards = [stats.copy(enabled: true), onboarding.copy(enabled: false), blaze]
        assertEqual(expectedCards, actualCards)
    }

}
