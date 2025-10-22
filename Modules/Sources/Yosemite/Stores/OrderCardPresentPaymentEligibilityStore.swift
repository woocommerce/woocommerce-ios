import Foundation
import protocol Storage.StorageManagerType
import protocol NetworkingCore.Network

/// Determines whether an order is eligible for card present payment or not
///
public final class OrderCardPresentPaymentEligibilityStore: Store {
    private let stores: () -> StoresManager
    private lazy var siteCIABEligibilityChecker: CIABEligibilityCheckerProtocol = CIABEligibilityChecker(stores: stores())

    public init(
        dispatcher: Dispatcher,
        storageManager: StorageManagerType,
        network: Network,
        stores: @escaping () -> StoresManager
    ) {
        self.stores = stores
        super.init(
            dispatcher: dispatcher,
            storageManager: storageManager,
            network: network
        )
    }

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

        guard let site = storage.loadSite(siteID: siteID)?.toReadOnly() else {
            return onCompletion(
                .failure(
                    OrderIsEligibleForCardPresentPaymentError.siteNotFoundInStorage
                )
            )
        }

        guard siteCIABEligibilityChecker.isFeatureSupported(.cardReader, for: site) else {
            return onCompletion(
                .failure(
                    OrderIsEligibleForCardPresentPaymentError.cardReaderPaymentOptionIsNotSupportedForCIABSites
                )
            )
        }

        guard let order = storage.loadOrder(siteID: siteID, orderID: orderID)?.toReadOnly() else {
            return onCompletion(.failure(OrderIsEligibleForCardPresentPaymentError.orderNotFoundInStorage))
        }

        let orderProductsIDs = order.items.map(\.productID)
        let products = storage.loadProducts(siteID: siteID, productsIDs: orderProductsIDs).map { $0.toReadOnly() }

        onCompletion(.success(order.isEligibleForCardPresentPayment(cardPresentPaymentsConfiguration: cardPresentPaymentsConfiguration, products: products)))
    }
}

extension OrderCardPresentPaymentEligibilityStore {
    enum OrderIsEligibleForCardPresentPaymentError: Error {
        case orderNotFoundInStorage
        case siteNotFoundInStorage
        case cardReaderPaymentOptionIsNotSupportedForCIABSites
    }
}
