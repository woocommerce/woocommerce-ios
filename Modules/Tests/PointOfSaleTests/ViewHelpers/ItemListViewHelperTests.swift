import Foundation
import Testing
@testable import PointOfSale

struct ItemListViewHelperTests {
    let sut = ItemListViewHelper()

    @Test func shouldShowCustomAmountEntryRow_when_all_conditions_met_then_true() {
        // Given
        // sut configured with the products tab, feature flag on, and not searching.

        // When
        let result = sut.shouldShowCustomAmountEntryRow(
            itemListType: .products(),
            isCustomAmountsFeatureEnabled: true,
            isSearching: false
        )

        // Then
        #expect(result == true)
    }

    @Test func shouldShowCustomAmountEntryRow_when_on_coupons_tab_then_false() {
        // Given
        // sut configured with the coupons tab; all other axes match the success case.

        // When
        let result = sut.shouldShowCustomAmountEntryRow(
            itemListType: .coupons(),
            isCustomAmountsFeatureEnabled: true,
            isSearching: false
        )

        // Then
        #expect(result == false)
    }

    @Test func shouldShowCustomAmountEntryRow_when_feature_flag_off_then_false() {
        // Given
        // sut configured with the feature flag off; all other axes match the success case.

        // When
        let result = sut.shouldShowCustomAmountEntryRow(
            itemListType: .products(),
            isCustomAmountsFeatureEnabled: false,
            isSearching: false
        )

        // Then
        #expect(result == false)
    }

    @Test func shouldShowCustomAmountEntryRow_when_searching_then_false() {
        // Given
        // sut configured with a search in progress; all other axes match the success case.

        // When
        let result = sut.shouldShowCustomAmountEntryRow(
            itemListType: .products(),
            isCustomAmountsFeatureEnabled: true,
            isSearching: true
        )

        // Then
        #expect(result == false)
    }
}
