import Foundation
import Yosemite

/// Determines the email to be set (if any) on a receipt
///
protocol ReceiptEmailParameterDeterminer {
    func receiptEmail(from order: Order) -> String?
}

/// Determines the email to be set (if any) on a payment receipt depending on the current payment plugins (WCPay, Stripe) configuration
///
struct PaymentReceiptEmailParameterDeterminer: ReceiptEmailParameterDeterminer {
    private let cardPresentPluginsDataProvider: CardPresentPluginsDataProviderProtocol
    private static let defaultConfiguration = CardPresentConfigurationLoader(stores: ServiceLocator.stores).configuration

    init(cardPresentPluginsDataProvider: CardPresentPluginsDataProviderProtocol = CardPresentPluginsDataProvider(configuration: Self.defaultConfiguration)) {
        self.cardPresentPluginsDataProvider = cardPresentPluginsDataProvider
    }

    /// We do not need to set the receipt email if WCPay is installed and active
    /// and its version is higher or equal than 4.0.0, as it does it itself in that case.
    ///
    /// - Parameters:
    ///   - order: the order associated with the payment
    /// - Returns:
    ///   - `String?`: the email for the reciept, if any. Even if there is an email, this will return `nil` for stores which send the receipt server-side.
    ///
    func receiptEmail(from order: Order) -> String? {
        let wcPay = cardPresentPluginsDataProvider.getWCPayPlugin()
        let stripe = cardPresentPluginsDataProvider.getStripePlugin()
        let paymentPluginsStatus = cardPresentPluginsDataProvider.paymentPluginsInstalledAndActiveStatus(wcPay: wcPay, stripe: stripe)

        guard paymentPluginsStatus != .bothAreInstalledAndActive else {
            return nil
        }

        guard let wcPay = wcPay,
              paymentPluginsStatus == .onlyWCPayIsInstalledAndActive else {
            return order.billingAddress?.email
        }

        return wcPayPluginSendsReceiptEmail(version: wcPay.version) ? nil : order.billingAddress?.email
    }

    private func wcPayPluginSendsReceiptEmail(version: String) -> Bool {
        VersionHelpers.isVersionSupported(version: version,
                                          minimumRequired: Constants.minimumWCPayPluginVersionThatSendsReceiptEmail)
    }
}

private extension PaymentReceiptEmailParameterDeterminer {
    enum Constants {
        static let minimumWCPayPluginVersionThatSendsReceiptEmail = "4.0.0"
    }
}
