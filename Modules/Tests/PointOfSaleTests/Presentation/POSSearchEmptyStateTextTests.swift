import Testing
@testable import PointOfSale

struct POSSearchEmptyStateTextTests {
    @Test func test_productSearch_when_no_results_then_shows_short_subtitle_and_variation_hint() {
        // Given
        let viewModel = POSListEmptyViewModel(itemListType: .products(search: true), baseItem: .root)

        // Then
        #expect(viewModel.title == "No products found")
        #expect(viewModel.subtitle == "Try a different search.")
        #expect(viewModel.hint == "To find a variation, search for its parent product.")
    }

    @Test func test_orderSearch_when_no_results_then_shows_short_subtitle() {
        // Given
        let viewModel = POSOrderListEmptyViewModel(isSearching: true)

        // Then
        #expect(viewModel.title == "No orders found")
        #expect(viewModel.subtitle == "Try a different search.")
        #expect(viewModel.hint == nil)
    }
}
