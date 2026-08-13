import Foundation
import Testing
import struct Yosemite.POSCoupon
import struct Yosemite.POSItemIdentifier
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

    // MARK: - shouldShowAppliedCouponIndicator

    @Test func shouldShowAppliedCouponIndicator_when_compact_layout_and_coupon_in_cart_then_true() {
        // Given
        let coupon = makeCoupon(itemID: 1)

        // When
        let result = sut.shouldShowAppliedCouponIndicator(
            coupon: coupon,
            cartCoupons: [makeCartCouponItem(from: coupon)],
            layoutScale: .compact
        )

        // Then
        #expect(result == true)
    }

    @Test func shouldShowAppliedCouponIndicator_when_regular_layout_and_coupon_in_cart_then_false() {
        // Given
        let coupon = makeCoupon(itemID: 1)

        // When
        let result = sut.shouldShowAppliedCouponIndicator(
            coupon: coupon,
            cartCoupons: [makeCartCouponItem(from: coupon)],
            layoutScale: .regular
        )

        // Then
        #expect(result == false)
    }

    @Test func shouldShowAppliedCouponIndicator_when_cart_empty_then_false() {
        // Given
        let coupon = makeCoupon(itemID: 1)

        // When
        let result = sut.shouldShowAppliedCouponIndicator(
            coupon: coupon,
            cartCoupons: [],
            layoutScale: .compact
        )

        // Then
        #expect(result == false)
    }

    @Test func shouldShowAppliedCouponIndicator_when_same_code_but_different_identifier_then_false() {
        // Given
        // Matching is by item identifier, mirroring POSItemActionHandler.shouldSkipDuplicate,
        // so a cart coupon with the same code but a different identifier does not count.
        let coupon = makeCoupon(itemID: 1)
        let sameCodeDifferentID = makeCoupon(itemID: 2)

        // When
        let result = sut.shouldShowAppliedCouponIndicator(
            coupon: coupon,
            cartCoupons: [makeCartCouponItem(from: sameCodeDifferentID)],
            layoutScale: .compact
        )

        // Then
        #expect(result == false)
    }
}

private extension ItemListViewHelperTests {
    func makeCoupon(itemID: Int64, code: String = "COUPON-10") -> POSCoupon {
        POSCoupon(id: POSItemIdentifier(underlyingType: .coupon, itemID: itemID),
                  code: code,
                  summary: "10% off - All Products")
    }

    func makeCartCouponItem(from coupon: POSCoupon) -> Cart.CouponItem {
        Cart.CouponItem(id: UUID(),
                        posItemIdentifier: coupon.id,
                        code: coupon.code,
                        summary: coupon.summary)
    }
}
