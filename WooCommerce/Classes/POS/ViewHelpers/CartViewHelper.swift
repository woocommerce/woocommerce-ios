import Foundation

final class CartViewHelper {
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
        guard paymentState.allowsCartEditing else {
            return true
        }
        return orderState.isSyncing
    }

    func shouldShowClearCartButton(cart: [CartItem], orderStage: PointOfSaleOrderStage) -> Bool {
        cart.isNotEmpty && orderStage == .building
    }
}

private extension PointOfSalePaymentState {
    var allowsCartEditing: Bool {
        switch self {
        case .processingPayment,
                .paymentError,
                .cardPaymentSuccessful,
                .validatingOrder,
                .preparingReader:
            return false
        case .idle,
                .validatingOrderError,
                .acceptingCard:
            return true
        }
    }
}
