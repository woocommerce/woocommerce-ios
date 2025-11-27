import Foundation
import protocol Storage.StorageManagerType
import protocol NetworkingCore.Network
import protocol WooFoundation.CrashLogger
import enum WooFoundation.SeverityLevel

/// Determines whether an order is eligible for card present payment or not
///
public final class OrderCardPresentPaymentEligibilityStore: Store {
    private let currentSite: () -> Site?
    private let isCIABEnvironmentSupported: () -> Bool
    private let crashLogger: CrashLogger
    private lazy var siteCIABEligibilityChecker: CIABEligibilityCheckerProtocol = CIABEligibilityChecker(
        currentSite: currentSite
    )

    public init(
        dispatcher: Dispatcher,
        storageManager: StorageManagerType,
        network: Network,
        crashLogger: CrashLogger,
        isCIABEnvironmentSupported: @escaping () -> Bool,
        currentSite: @escaping () -> Site?
    ) {
        self.currentSite = currentSite
        self.isCIABEnvironmentSupported = isCIABEnvironmentSupported
        self.crashLogger = crashLogger
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

        /// The following checks are only relevant if CIAB is rolled out.
        if isCIABEnvironmentSupported() {
            let storageSite = storage.loadSite(siteID: siteID)?.toReadOnly()

            let site: Site?
            if let storageSite {
                site = storageSite
            } else {
                /// Non - fatal fallback to `currentSite` when a storage site is missing
                site = currentSite()

                logFailedStorageSiteRead(
                    siteID: siteID,
                    currentSiteFallbackValue: site
                )
            }

            guard let site else {
                logFailedDefaultSiteRead(siteID: siteID)

                return onCompletion(
                    .failure(
                        OrderIsEligibleForCardPresentPaymentError.failedToObtainSite
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
        }

        guard let order = storage.loadOrder(siteID: siteID, orderID: orderID)?.toReadOnly() else {
            return onCompletion(.failure(OrderIsEligibleForCardPresentPaymentError.orderNotFoundInStorage))
        }

        let orderProductsIDs = order.items.map(\.productID)
        let products = storage.loadProducts(siteID: siteID, productsIDs: orderProductsIDs).map { $0.toReadOnly() }

        onCompletion(.success(order.isEligibleForCardPresentPayment(cardPresentPaymentsConfiguration: cardPresentPaymentsConfiguration, products: products)))
    }
}

/// Error logging
private extension OrderCardPresentPaymentEligibilityStore {
    func logFailedStorageSiteRead(siteID: Int64, currentSiteFallbackValue: Site?) {
        let message = "OrderCardPresentPaymentEligibilityStore: Storage site missing, falling back to currentSite."

        DDLogError(message)

        crashLogger.logMessage(
            message,
            properties: [
                "siteID": siteID,
                "currentSiteID": currentSiteFallbackValue?.siteID ?? "empty",
            ],
            level: .error
        )
    }

    func logFailedDefaultSiteRead(siteID: Int64) {
        let message = "OrderCardPresentPaymentEligibilityStore: Current default site missing."

        DDLogError(message)

        crashLogger.logMessage(
            "OrderCardPresentPaymentEligibilityStore: Current default site missing.",
            properties: [
                "requestedSiteID": siteID
            ],
            level: .error
        )
    }
}

extension OrderCardPresentPaymentEligibilityStore {
    enum OrderIsEligibleForCardPresentPaymentError: Error {
        case orderNotFoundInStorage
        case failedToObtainSite
        case cardReaderPaymentOptionIsNotSupportedForCIABSites
    }
}
