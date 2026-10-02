import Foundation
import Networking
import Storage

/// Determines whether an order is eligible for card present payment or not
///
public final class OrderCardPresentPaymentEligibilityStore: Store {
    private let subscriptionsRemote: SubscriptionsRemoteProtocol

    /// Successful subscription lookups, keyed by site and order because order IDs aren't unique across sites.
    /// Failures aren't cached so that they're retried on the next check.
    ///
    private var orderContainsSubscriptionCache: [OrderKey: Bool] = [:]

    override public init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        self.subscriptionsRemote = SubscriptionsRemote(network: network)
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network, subscriptionsRemote: SubscriptionsRemoteProtocol) {
        self.subscriptionsRemote = subscriptionsRemote
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
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
        case .checkEligibility(let orderID, let siteID, let cardPresentPaymentsConfiguration, let onCompletion):
            checkEligibility(orderID: orderID,
                             siteID: siteID,
                             cardPresentPaymentsConfiguration: cardPresentPaymentsConfiguration,
                             onCompletion: onCompletion)
        case .checkOrderContainsSubscription(let orderID, let siteID, let onCompletion):
            checkOrderContainsSubscription(orderID: orderID, siteID: siteID, onCompletion: onCompletion)
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

    /// Legacy subscription product types are recognized locally. Otherwise, the subscriptions with the order as their parent are fetched,
    /// which also catches plan-based subscriptions (a subscription plan on any product type).
    /// Renewal orders aren't parents of a subscription, so they stay collectible unless they contain a legacy subscription product.
    ///
    func checkOrderContainsSubscription(orderID: Int64,
                                        siteID: Int64,
                                        onCompletion: @escaping (Result<Bool, Error>) -> Void) {
        let storage = storageManager.viewStorage

        guard let order = storage.loadOrder(siteID: siteID, orderID: orderID)?.toReadOnly() else {
            DDLogWarn("[Card payment eligibility] siteID=\(siteID) orderID=\(orderID) reason=order_not_found_in_storage")
            return onCompletion(.failure(OrderIsEligibleForCardPresentPaymentError.orderNotFoundInStorage))
        }

        // Without products, or without Woo Subscriptions active, the order can't contain a subscription.
        let productIDs = order.items.map(\.productID).filter { $0 != 0 }
        let isWooSubscriptionsActive = storage.loadSystemPlugin(siteID: siteID,
                                                                fileNameWithoutExtension: Plugin.wooSubscriptions.fileNameWithoutExtension,
                                                                active: true) != nil
        guard !productIDs.isEmpty, isWooSubscriptionsActive else {
            return onCompletion(.success(false))
        }

        let products = storage.loadProducts(siteID: siteID, productsIDs: productIDs).map { $0.toReadOnly() }
        if products.contains(where: { $0.productType.isSubscription }) {
            return onCompletion(.success(true))
        }

        let key = OrderKey(siteID: siteID, orderID: orderID)
        if let containsSubscription = orderContainsSubscriptionCache[key] {
            return onCompletion(.success(containsSubscription))
        }

        subscriptionsRemote.loadSubscriptions(siteID: siteID, orderID: orderID) { [weak self] result in
            switch result {
            case .success(let subscriptions):
                let containsSubscription = !subscriptions.isEmpty
                self?.orderContainsSubscriptionCache[key] = containsSubscription
                onCompletion(.success(containsSubscription))
            case .failure(let error):
                DDLogError("⛔️ [Card payment eligibility] siteID=\(siteID) orderID=\(orderID) reason=subscriptions_fetch_failed error=\(error)")
                onCompletion(.failure(error))
            }
        }
    }
}

private extension OrderCardPresentPaymentEligibilityStore {
    struct OrderKey: Hashable {
        let siteID: Int64
        let orderID: Int64
    }
}

extension OrderCardPresentPaymentEligibilityStore {
    enum OrderIsEligibleForCardPresentPaymentError: Error {
        case orderNotFoundInStorage
    }
}
