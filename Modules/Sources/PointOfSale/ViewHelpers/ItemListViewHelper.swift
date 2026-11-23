import Foundation
import struct Yosemite.POSCoupon

struct ItemListViewHelper {
    /// Whether a coupon row in the item list should show the applied indicator
    /// (green checkmark tile) because the coupon is already in the cart.
    ///
    /// Phone-only: on compact layout the cart lives behind a sheet, so the list is
    /// the only visible feedback that a tapped coupon was applied. On regular layout
    /// the cart is always on screen and already shows applied coupons.
    func shouldShowAppliedCouponIndicator(coupon: POSCoupon,
                                          cartCoupons: [Cart.CouponItem],
                                          layoutScale: POSLayoutScale) -> Bool {
        guard layoutScale == .compact else {
            return false
        }
        return cartCoupons.contains(where: { $0.posItemIdentifier == coupon.id })
    }

    /// Whether the products list should show the entry row that opens the
    /// custom amount form.
    ///
    /// Custom amounts only make sense in the products tab. The Coupons tab and the
    /// search surface reuse the same list view for unrelated content, so the row
    /// is gated to non-searching products.
    ///
    /// `orderStage` is intentionally not part of this decision: at `.finalizing`
    /// the products list slides off-screen via the dashboard offset (or is replaced
    /// entirely on phone), so hiding the row here was redundant and produced a
    /// visible flash — the row vanished synchronously while the slide animation
    /// was still running, leaving an empty slot at the top of the list mid-transition.
    func shouldShowCustomAmountEntryRow(itemListType: ItemListType,
                                        isCustomAmountsFeatureEnabled: Bool,
                                        isSearching: Bool) -> Bool {
        guard case .products = itemListType else { return false }
        guard isCustomAmountsFeatureEnabled else { return false }
        return !isSearching
    }

    /// Whether the phone cart button should hide because the visible list screen is a full-screen
    /// error, or a pushed product's empty variations screen. Both already have their own primary button.
    /// Root empty screens keep the cart button.
    ///
    /// - Parameter pushedParentState: State of the variable product pushed on top of the list, if any.
    ///   When set, it alone decides, since it covers the root list.
    func hidesCompactCartButton(rootState: ItemListState,
                                isShowingPreSearch: Bool,
                                pushedParentState: ItemListState?) -> Bool {
        if let pushedParentState {
            // Mirrors the states ChildItemList shows as its empty or error screen.
            switch pushedParentState {
            case .initial, .loaded([], _), .empty, .error:
                return true
            case .loading, .loaded, .inlineError:
                return false
            }
        }
        guard !isShowingPreSearch else {
            return false
        }
        if case .error = rootState {
            return true
        }
        return false
    }
}
