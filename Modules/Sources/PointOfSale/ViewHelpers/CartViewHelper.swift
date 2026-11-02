import Foundation
import WooFoundation

struct CartViewHelper {
    func itemsInCartLabel(for itemsCount: Int) -> String? {
        guard itemsCount > 0 else {
            return nil
        }
        return String.pluralize(itemsCount,
                                singular: Localization.itemCountSingular,
                                plural: Localization.itemCountPlural)
    }

    private enum Localization {
        static let itemCountSingular = NSLocalizedString(
            "pos.cart.itemCount.singular", value: "%1$d item",
            comment: "Number of items in the cart when there is one item. %1$d is the number of items."
        )
        static let itemCountPlural = NSLocalizedString(
            "pos.cart.itemCount.plural", value: "%1$d items",
            comment: "Number of items in the cart when there are multiple items. %1$d is the number of items."
        )
    }

    func shouldPreventCartEditing(paymentState: PointOfSalePaymentState) -> Bool {
        guard paymentState.card.allowsCartEditing else {
            return true
        }
        // Cash / Scan to Pay / Mark as Paid block cart editing while their flow
        // is mid-progress (showing the QR view, confirming, processing) AND
        // while their success UI is up on the totals view. Without this, the
        // "back to cart" arrow on the phone Checkout header stays enabled on
        // top of the success screen, and tapping it would let the merchant
        // re-edit an order that's already been paid.
        if paymentState.cash != .idle { return true }
        if paymentState.scanToPay != .idle { return true }
        return paymentState.markAsPaid != .idle
    }

    func shouldShowClearCartButton(cart: Cart, orderStage: PointOfSaleOrderStage) -> Bool {
        cart.isNotEmpty && orderStage == .building
    }

    func shouldShowCheckout(orderStage: PointOfSaleOrderStage, cart: Cart) -> Bool {
        guard case .building = orderStage else { return false }

        return cart.purchasableItems.isNotEmpty || cart.customAmounts.isNotEmpty
    }

    func hasUnresolvedItems(cart: Cart) -> Bool {
        cart.purchasableItems.contains { item in
            switch item.state {
            case .loading, .error:
                return true
            case .loaded:
                return false
            }
        }
    }
}

private extension PointOfSaleCardPaymentState {
    var allowsCartEditing: Bool {
        switch self {
        case .processingPayment,
                .paymentError,
                .cardPaymentSuccessful,
                .cardInserted:
            return false
        case .idle,
                .validatingOrder,
                .validatingOrderError,
                .paymentIntentCreationError,
                .preparingReader,
                .acceptingCard:
            return true
        }
    }
}

// MARK: - Coupons

enum CouponRowState: Equatable {
    case idle
    case validating
    case valid(PointOfSaleCouponTotal)
    case invalid
}

extension CartViewHelper {
    /// Coupons never discount custom amounts (order fees), so the custom amount rows warn
    /// about it at checkout — but only for whole-cart coupons ("x% off" / "$x off cart"),
    /// where a merchant could expect the custom amount to be included, and only once the
    /// order response shows the coupon actually produced a discount.
    func shouldShowCustomAmountDiscountNotAppliedNote(
        orderStage: PointOfSaleOrderStage,
        orderState: PointOfSaleOrderState,
        cart: Cart
    ) -> Bool {
        guard orderStage == .finalizing,
              case .loaded(let totals) = orderState else {
            return false
        }

        let discountingCoupons = totals.couponsTotals.filter(\.hasDiscount)
        guard discountingCoupons.isNotEmpty else {
            return false
        }

        return cart.coupons.contains { coupon in
            coupon.appliesToWholeCart && discountingCoupons.contains { $0.matches(code: coupon.code) }
        }
    }

    /// Positively marks the cart rows the order response shows as discounted, whatever the
    /// discount's source — a product-restricted coupon, a whole-cart coupon, or a plugin.
    func shouldShowItemDiscountedNote(
        orderStage: PointOfSaleOrderStage,
        orderState: PointOfSaleOrderState,
        cartItem: Cart.PurchasableItem
    ) -> Bool {
        guard orderStage == .finalizing,
              case .loaded(let totals) = orderState else {
            return false
        }

        return totals.discountedCartItemIDs.contains(cartItem.id)
    }

    func couponRowState(
        orderStage: PointOfSaleOrderStage,
        orderState: PointOfSaleOrderState,
        couponItem: Cart.CouponItem
    ) -> CouponRowState {
        guard orderStage == .finalizing else {
            return .idle
        }

        switch orderState {
        case .syncing:
            return .validating
        case .loaded(let totals):
            if let couponTotal = totals.couponsTotals
                .first(where: { $0.matches(code: couponItem.code) }) {
                    return .valid(couponTotal)
                } else {
                    return .idle
                }
        case .error(.invalidCoupon, _):
            return .invalid
        default:
            return .idle
        }
    }
}

private extension PointOfSaleCouponTotal {
    /// WooCommerce treats coupon codes as case-insensitive, and the code in the order
    /// response may be cased differently from the one the merchant added to the cart.
    func matches(code: String) -> Bool {
        self.code.caseInsensitiveCompare(code) == .orderedSame
    }
}
