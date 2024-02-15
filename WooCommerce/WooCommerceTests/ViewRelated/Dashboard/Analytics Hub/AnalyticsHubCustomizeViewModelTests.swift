import XCTest
@testable import WooCommerce

final class AnalyticsHubCustomizeViewModelTests: XCTestCase {

    func test_it_inits_with_expected_properties() {
        // Given
        let allCards = ["First", "Second"]
        let selectedCards = Set(["Second"])
        let vm = AnalyticsHubCustomizeViewModel(allCards: allCards, selectedCards: selectedCards)

        // Then
        assertEqual(allCards, vm.allCards)
        assertEqual(selectedCards, vm.selectedCards)
    }

}
