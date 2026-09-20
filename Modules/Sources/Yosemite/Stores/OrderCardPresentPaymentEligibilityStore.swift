import Foundation

/// Determines whether an order is eligible for card present payment or not
///
public final class OrderCardPresentPaymentEligibilityStore: Store {

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: OrderCardPresentPaymentEligibilityAction.self)
    }

    /// Receives and executes Actions.
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? OrderCardPresentPaymentEligibilityAction else {
            assertionFailure("OrderCardPresentPaymentEligibilityStore received an unsupported action")
            return
        }

        switch action {
        case .checkEligibility(let orderID, let siteID, let cardPresentPaymentsConfiguration, let onCompletion):
            checkEligibility(orderID: orderID,
                             siteID: siteID,
                             cardPresentPaymentsConfiguration: cardPresentPaymentsConfiguration,
                             onCompletion: onCompletion)
        }
    }
}

private extension OrderCardPresentPaymentEligibilityStore {
    func checkEligibility(orderID: Int64,
                          siteID: Int64,
                          cardPresentPaymentsConfiguration: CardPresentPaymentsConfiguration,
                          onCompletion: (Result<OrderCardPresentPaymentEligibility, Error>) -> Void) {
        let storage = storageManager.viewStorage

        guard let order = storage.loadOrder(siteID: siteID, orderID: orderID)?.toReadOnly() else {
            DDLogWarn("[Card payment eligibility] siteID=\(siteID) orderID=\(orderID) reason=order_not_found_in_storage")
            return onCompletion(.failure(OrderIsEligibleForCardPresentPaymentError.orderNotFoundInStorage))
        }

        let orderProductsIDs = order.items.map(\.productID)
        let products = storage.loadProducts(siteID: siteID, productsIDs: orderProductsIDs).map { $0.toReadOnly() }

        onCompletion(.success(order.cardPresentPaymentEligibility(cardPresentPaymentsConfiguration: cardPresentPaymentsConfiguration, products: products)))
    }
}

extension OrderCardPresentPaymentEligibilityStore {
    enum OrderIsEligibleForCardPresentPaymentError: Error {
        case orderNotFoundInStorage
    }
}
