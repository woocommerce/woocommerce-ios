import Foundation
import Testing
@testable import PointOfSale

struct ItemListViewHelperTests {
    let sut = ItemListViewHelper()

    @Test func shouldShowCustomAmountEntryRow_when_all_conditions_met_then_true() {
        #expect(sut.shouldShowCustomAmountEntryRow(
            itemListType: .products(),
            isCustomAmountsFeatureEnabled: true,
            orderStage: .building,
            isSearching: false
        ) == true)
    }

    @Test func shouldShowCustomAmountEntryRow_when_on_coupons_tab_then_false() {
        #expect(sut.shouldShowCustomAmountEntryRow(
            itemListType: .coupons(),
            isCustomAmountsFeatureEnabled: true,
            orderStage: .building,
            isSearching: false
        ) == false)
    }

    @Test func shouldShowCustomAmountEntryRow_when_feature_flag_off_then_false() {
        #expect(sut.shouldShowCustomAmountEntryRow(
            itemListType: .products(),
            isCustomAmountsFeatureEnabled: false,
            orderStage: .building,
            isSearching: false
        ) == false)
    }

    @Test func shouldShowCustomAmountEntryRow_when_order_finalizing_then_false() {
        #expect(sut.shouldShowCustomAmountEntryRow(
            itemListType: .products(),
            isCustomAmountsFeatureEnabled: true,
            orderStage: .finalizing,
            isSearching: false
        ) == false)
    }

    @Test func shouldShowCustomAmountEntryRow_when_searching_then_false() {
        #expect(sut.shouldShowCustomAmountEntryRow(
            itemListType: .products(),
            isCustomAmountsFeatureEnabled: true,
            orderStage: .building,
            isSearching: true
        ) == false)
    }
}
