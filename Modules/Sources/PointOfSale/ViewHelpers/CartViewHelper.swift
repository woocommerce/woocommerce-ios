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
        return orderState.isSyncing
    }

    func shouldShowClearCartButton(cart: Cart, orderStage: PointOfSaleOrderStage) -> Bool {
        cart.isNotEmpty && orderStage == .building
    }

    func shouldShowCheckout(orderStage: PointOfSaleOrderStage, cart: Cart) -> Bool {
        guard case .building = orderStage else { return false }

        return cart.purchasableItems.isNotEmpty
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
