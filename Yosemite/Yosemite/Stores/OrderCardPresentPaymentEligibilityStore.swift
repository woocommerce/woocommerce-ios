
import Foundation

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
        case .orderIsEligibleForCardPresentPayment(let orderID, let siteID, let cardPresentPaymentsConfiguration, let onCompletion):
        orderIsEligibleForCardPresentPayment(orderID: orderID,
                                             siteID: siteID,
                                             cardPresentPaymentsConfiguration: cardPresentPaymentsConfiguration,
                                             onCompletion: onCompletion)
        }
    }

}

private extension OrderCardPresentPaymentEligibilityStore {
    func orderIsEligibleForCardPresentPayment(orderID: Int64,
                                              siteID: Int64,
                                              cardPresentPaymentsConfiguration: CardPresentPaymentsConfiguration,
                                              onCompletion: (Result<Bool, Error>) -> Void) {
        let storage = storageManager.viewStorage
        guard let order = storage.loadOrder(siteID: siteID, orderID: orderID)?.toReadOnly() else {
            return onCompletion(.failure(OrderIsEligibleForCardPresentPaymentError.orderNotFoundInStorage))
        }


        let orderProductsIDs = order.items.map(\.variationID)
        let products = storage.loadProducts(siteID: siteID, productsIDs: orderProductsIDs).map { $0.toReadOnly() }

        onCompletion(.success(order.isEligibleForCardPresentPayment(cardPresentPaymentsConfiguration: cardPresentPaymentsConfiguration, products: products)))
    }
}

extension OrderCardPresentPaymentEligibilityStore {
    enum OrderIsEligibleForCardPresentPaymentError: Error {
        case orderNotFoundInStorage
    }
}
