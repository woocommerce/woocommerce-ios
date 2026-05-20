import Foundation
import Yosemite
import Experiments
import class WooFoundation.VersionHelpers

protocol ReceiptEligibilityUseCaseProtocol {
    func isEligibleForBackendReceipts(onCompletion: @escaping (Bool) -> Void)
    func isEligibleForSuccessfulPaymentEmailReceipts(onCompletion: @escaping (Bool) -> Void)
    func isEligibleForFailedPaymentEmailReceipts(paymentGatewayID: String, onCompletion: @escaping (Bool) -> Void)
    func isEligibleForReceipt(_ orderStatus: OrderStatusEnum, datePaid: Date?, onCompletion: @escaping (Bool) -> Void)
}

final class ReceiptEligibilityUseCase: ReceiptEligibilityUseCaseProtocol {
    private let stores: StoresManager
    private let pluginsService: PluginsServiceProtocol
    private let featureFlagService: FeatureFlagService

    private var siteID: Int64 {
        stores.sessionManager.defaultStoreID ?? 0
    }

    init(stores: StoresManager = ServiceLocator.stores,
         pluginsService: PluginsServiceProtocol = PluginsService(storageManager: ServiceLocator.storageManager),
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        self.stores = stores
        self.pluginsService = pluginsService
        self.featureFlagService = featureFlagService
    }

    func isEligibleForBackendReceipts(onCompletion: @escaping (Bool) -> Void) {
        Task { @MainActor in
            let isWooCommerceSupported = await isPluginSupported(.wooCommerce,
                                                                 minimumVersion: Constants.BackendReceipt.wcPluginMinimumVersion)
            onCompletion(isWooCommerceSupported)
        }
    }

    /// Returns true if In Person Payments allows sending successful payment email receipts via the API.
    /// WooCommerce 9.5 allows to attach a customer email after payment is made and send email receipt via the API.
    ///
    func isEligibleForSuccessfulPaymentEmailReceipts(onCompletion: @escaping (Bool) -> Void) {
        Task { @MainActor in
            let isWooCommerceSupported = await isPluginSupported(.wooCommerce,
                                                                 minimumVersion: Constants.PointOfSaleReceipts.wcPluginMinimumVersion)
            onCompletion(isWooCommerceSupported)
        }
    }

    /// Returns true if In Person Payments allows sending failed payment email receipts via the API.
    /// WooCommerce 9.5 allows to attach a customer email after payment is made and send email receipt via the API.
    /// WooCommerce 9.5 automatically sends failure receipt after the order fails if the customer email is attached to the order.
    /// WooPayments 8.6 aligns the app with the web and automatically sets the order as failed when the payment processing fails.
    /// WooCommerce Stripe Gateway 9.1.0 aligns the app with the web and automatically sets the order as failed when the payment processing fails.
    ///
    func isEligibleForFailedPaymentEmailReceipts(paymentGatewayID: String, onCompletion: @escaping (Bool) -> Void) {
        Task { @MainActor in
            async let wooCommerceSupported = isPluginSupported(.wooCommerce,
                                                               minimumVersion: Constants.ReceiptAfterPayment.wcPluginMinimumVersion)

            async let gatewaySupported: Bool = {
                switch paymentGatewayID {
                case CardPresentPaymentsPlugin.wcPay.gatewayID:
                    return await isPluginSupported(.wooPayments,
                                                   minimumVersion: Constants.ReceiptAfterPayment.wcPayPluginMinimumVersion)
                case CardPresentPaymentsPlugin.stripe.gatewayID:
                    return await isPluginSupported(.stripe,
                                                   minimumVersion: Constants.ReceiptAfterPayment.stripePluginMinimumVersion)
                default:
                    return false
                }
            }()

            let (isWooCommerceSupported, isGatewaySupported) = await (wooCommerceSupported, gatewaySupported)
            onCompletion(isWooCommerceSupported && isGatewaySupported)
        }
    }

    func isEligibleForReceipt(_ orderStatus: OrderStatusEnum, datePaid: Date?, onCompletion: @escaping (Bool) -> Void) {
        switch orderStatus {
        case .completed, .processing, .refunded:
            isEligibleForBackendReceipts { isEligibleForReceipt in
                onCompletion(isEligibleForReceipt)
            }
        case .custom:
            guard datePaid != nil else {
                onCompletion(false)
                return
            }
            isEligibleForBackendReceipts { isEligibleForReceipt in
                onCompletion(isEligibleForReceipt)
            }
        case .failed:
            selectedPaymentGatewayID { [weak self] gatewayID in
                guard let gatewayID else {
                    return onCompletion(false)
                }
                self?.isEligibleForFailedPaymentEmailReceipts(paymentGatewayID: gatewayID) { isEligibleForReceipt in
                    onCompletion(isEligibleForReceipt)
                }
            }
        default:
            onCompletion(false)
            return
        }
    }
}

private extension ReceiptEligibilityUseCase {
    @MainActor
    func isPluginSupported(_ plugin: Plugin, minimumVersion: String) async -> Bool {
        // Plugin must be installed and active
        guard let systemPlugin = pluginsService.loadPluginInStorage(siteID: siteID, plugin: plugin, isActive: true),
              systemPlugin.active else {
            return false
        }

        // If plugin version is higher than minimum required version, mark as eligible
        let isSupported = VersionHelpers.isVersionSupported(version: systemPlugin.version,
                                                            minimumRequired: minimumVersion)
        return isSupported
    }

    // Returns the current payment gateway ID, needed when checking if a transaction is eligible for receipts
    // based on which plugin and versions are active
    private func selectedPaymentGatewayID(onCompletion: @escaping (String?) -> Void) {
        let action = CardPresentPaymentAction.selectedPaymentGatewayAccount { paymentGatewayAccount in
            onCompletion(paymentGatewayAccount?.gatewayID)
        }
        stores.dispatch(action)
    }
}

private extension ReceiptEligibilityUseCase {
    enum Constants {
        enum BackendReceipt {
            static let wcPluginMinimumVersion = "8.7.0"
        }

        enum ReceiptAfterPayment {
            static let wcPluginMinimumVersion = "9.5.0"
            static let wcPayPluginMinimumVersion = "8.6.0"
            static let stripePluginMinimumVersion = "9.1.0"
        }

        enum PointOfSaleReceipts {
            static let wcPluginMinimumVersion = "9.5.0"
        }
    }
}
