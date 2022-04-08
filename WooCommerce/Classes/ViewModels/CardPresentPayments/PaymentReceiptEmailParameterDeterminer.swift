import Foundation
import Yosemite

/// Determines the email to be set (if any) on a payment receipt depending on the current payment plugins (WCPay, Stripe) configuration
/// 
struct PaymentReceiptEmailParameterDeterminer {
    private let paymentsPluginsDataProvider: PaymentsPluginsDataProviderProtocol
    private let stores: StoresManager

    init(paymentsPluginsDataProvider: PaymentsPluginsDataProviderProtocol = PaymentsPluginsDataProvider(),
         stores: StoresManager = ServiceLocator.stores) {
        self.paymentsPluginsDataProvider = paymentsPluginsDataProvider
        self.stores = stores
    }

    /// We do not need to set the receipt email if WCPay is installed and active
    /// and its version is higher or equal than 4.0.0, as it does it itself in that case.
    ///
    /// - Parameters:
    ///   - order: the order associated with the payment
    ///   - onCompletion: closure invoked with the result of the inquiry, containg the email (if any) or error
    ///
    func receiptEmail(from order: Order, onCompletion: @escaping ((Result<String?, Error>) -> Void)) {
        synchronizePlugins(from: order.siteID) { result in
            switch result {
            case .success():
                onCompletion(Result.success(receiptEmail(from: order)))
            case let .failure(error):
                onCompletion(Result.failure(error))
            }
        }
    }

    private func receiptEmail(from order: Order) -> String? {
        let wcPay = paymentsPluginsDataProvider.getWCPayPlugin()
        let stripe = paymentsPluginsDataProvider.getStripePlugin()

        guard !paymentsPluginsDataProvider.bothPluginsInstalledAndActive(wcPay: wcPay, stripe: stripe) else {
            // This case should not happen, shall we fatal error here?
            return nil
        }

        guard let wcPay = wcPay,
              paymentsPluginsDataProvider.wcPayInstalledAndActive(wcPay: wcPay) else {
            return order.billingAddress?.email
        }

        return wcPayPluginSendsReceiptEmail(version: wcPay.version) ? nil : order.billingAddress?.email
    }

    private func synchronizePlugins(from siteID: Int64, onCompletion: @escaping ((Result<Void, Error>) -> Void)) {
        let systemPluginsAction = SystemStatusAction.synchronizeSystemPlugins(siteID: siteID) { result in
            if case let .failure(error) = result {
                DDLogError("[PaymentCaptureOrchestrator] Error syncing system plugins: \(error)")
                onCompletion(Result.failure(error))
            } else {
                onCompletion(Result.success(()))
            }
        }

        stores.dispatch(systemPluginsAction)
    }

    private func wcPayPluginSendsReceiptEmail(version: String) -> Bool {
        let comparisonResult = VersionHelpers.compare(version, Constants.minimumWCPayPluginVersionThatSendsReceiptEmail)

        return comparisonResult == .orderedDescending || comparisonResult == .orderedSame
    }
}

private extension PaymentReceiptEmailParameterDeterminer {
    enum Constants {
        static let minimumWCPayPluginVersionThatSendsReceiptEmail = "4.0.0"
    }
}
