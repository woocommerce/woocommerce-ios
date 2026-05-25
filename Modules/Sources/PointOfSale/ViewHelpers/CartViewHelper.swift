import Foundation
import WooFoundation

struct CartViewHelper {
    func itemsInCartLabel(for itemsCount: Int) -> String? {
        guard itemsCount > 0 else {
            return nil
        }
        return String.pluralize(itemsCount,
                                singular: "%1$d item",
                                plural: "%1$d items")
    }

    func shouldPreventCartEditing(orderState: PointOfSaleOrderState,
                                  paymentState: PointOfSalePaymentState) -> Bool {
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
        if paymentState.markAsPaid != .idle { return true }
        return orderState.isSyncing
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
                .validatingOrder,
                .preparingReader,
                .cardInserted:
            return false
        case .idle,
                .validatingOrderError,
                .paymentIntentCreationError,
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
                .first(where: { $0.code == couponItem.code }) {
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
