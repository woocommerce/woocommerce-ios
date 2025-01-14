import Yosemite
import Experiments

protocol ReceiptEligibilityUseCaseProtocol {
    func isEligibleForBackendReceipts(onCompletion: @escaping (Bool) -> Void)
    func isEligibleForSuccessfulPaymentEmailReceipts(onCompletion: @escaping (Bool) -> Void)
    func isEligibleForFailedPaymentEmailReceipts(paymentGatewayID: String, onCompletion: @escaping (Bool) -> Void)
}

final class ReceiptEligibilityUseCase: ReceiptEligibilityUseCaseProtocol {
    private let stores: StoresManager
    private let featureFlagService: FeatureFlagService
    private let cardPresentPaymentsOnboarding: CardPresentPaymentsOnboardingUseCaseProtocol

    private var siteID: Int64 {
        stores.sessionManager.defaultStoreID ?? 0
    }

    init(stores: StoresManager = ServiceLocator.stores,
         cardPresentPaymentsOnboarding: CardPresentPaymentsOnboardingUseCaseProtocol = CardPresentPaymentsOnboardingUseCase(),
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        self.stores = stores
        self.cardPresentPaymentsOnboarding = cardPresentPaymentsOnboarding
        self.featureFlagService = featureFlagService
    }

    func isEligibleForBackendReceipts(onCompletion: @escaping (Bool) -> Void) {
        guard featureFlagService.isFeatureFlagEnabled(.backendReceipts) else {
            onCompletion(false)
            return
        }

        let action = SystemStatusAction.fetchSystemPlugin(siteID: siteID, systemPluginName: Constants.wcPluginName) { wcPlugin in
            // 1. WooCommerce must be installed and active
            guard let wcPlugin = wcPlugin, wcPlugin.active else {
                return onCompletion(false)
            }
            // 2. If WooCommerce version is any of the specific API development branches, mark as eligible
            if Constants.BackendReceipt.wcPluginDevVersion.contains(wcPlugin.version) {
                onCompletion(true)
            } else {
                // 3. Else, if WooCommerce version is higher than minimum required version, mark as eligible
                let isSupported = VersionHelpers.isVersionSupported(version: wcPlugin.version,
                                                                    minimumRequired: Constants.BackendReceipt.wcPluginMinimumVersion)
                onCompletion(isSupported)
            }
        }
        stores.dispatch(action)
    }

    /// Returns true if Point of Sale allows sending successful payment email receipts via the API.
    /// WooCommerce 9.5 allows to attach a customer email after payment is made and send email receipt via the API.
    ///
    func isEligibleForPointOfSaleReceipts(onCompletion: @escaping (Bool) -> Void) {
        guard featureFlagService.isFeatureFlagEnabled(.sendReceiptsForPointOfSale) else {
            onCompletion(false)
            return
        }

        Task { @MainActor in
            let isWooCommerceSupported = await isPluginSupported(Constants.wcPluginName,
                                                                 minimumVersion: Constants.PointOfSaleReceipts.wcPluginMinimumVersion)
            onCompletion(isWooCommerceSupported)
        }
    }

    /// Returns true if In Person Payments allows sending successful payment email receipts via the API.
    /// WooCommerce 9.5 allows to attach a customer email after payment is made and send email receipt via the API.
    ///
    func isEligibleForSuccessfulPaymentEmailReceipts(onCompletion: @escaping (Bool) -> Void) {
        guard featureFlagService.isFeatureFlagEnabled(.sendReceiptAfterPayment) else {
            return onCompletion(false)
        }

        Task { @MainActor in
            let isWooCommerceSupported = await isPluginSupported(Constants.wcPluginName,
                                                                 minimumVersion: Constants.PointOfSaleReceipts.wcPluginMinimumVersion)
            onCompletion(isWooCommerceSupported)
        }
    }

    /// Returns true if In Person Payments allows sending failed payment email receipts via the API.
    /// WooCommerce 9.5 allows to attach a customer email after payment is made and send email receipt via the API.
    /// WooCommerc 9.5 automatically sends failure receipt after the order fails if the customer email is attached to the order.
    /// WooPayments 8.6 aligns the app with the web and automatically sets the order as failed when the payment processing fails.
    /// WooCommerce Stripe Gateway 9.1.0 aligns the app with the web and automatically sets the order as failed when the payment processing fails.
    ///
    func isEligibleForFailedPaymentEmailReceipts(paymentGatewayID: String, onCompletion: @escaping (Bool) -> Void) {
        guard featureFlagService.isFeatureFlagEnabled(.sendReceiptAfterPayment) else {
            return onCompletion(false)
        }

        switch paymentGatewayID {
        case CardPresentPaymentsPlugin.wcPay.gatewayID:
            Task { @MainActor in
                async let isWooCommerceSupported = isPluginSupported(Constants.wcPluginName,
                                                                     minimumVersion: Constants.ReceiptAfterPayment.wcPluginMinimumVersion)
                async let isWooPaymentsSupported = isPluginSupported(CardPresentPaymentsPlugin.wcPay.pluginName,
                                                                     minimumVersion: Constants.ReceiptAfterPayment.wcPayPluginMinimumVersion)
                let wooCommerceResult = await isWooCommerceSupported
                let wooPaymentsResult = await isWooPaymentsSupported
                let isSupported = wooCommerceResult && wooPaymentsResult

                onCompletion(isSupported)
            }
        case CardPresentPaymentsPlugin.stripe.gatewayID:
            Task { @MainActor in
                async let isWooCommerceSupported = isPluginSupported(Constants.wcPluginName,
                                                                     minimumVersion: Constants.ReceiptAfterPayment.wcPluginMinimumVersion)
                async let isStripeSupported = isPluginSupported(CardPresentPaymentsPlugin.stripe.pluginName,
                                                                minimumVersion: Constants.ReceiptAfterPayment.stripePluginMinimumVersion)
                let wooCommerceResult = await isWooCommerceSupported
                let stripeResult = await isStripeSupported
                let isSupported = wooCommerceResult && stripeResult

                onCompletion(isSupported)
            }
        default:
            onCompletion(false)
        }
    }
}

private extension ReceiptEligibilityUseCase {
    @MainActor
    func isPluginSupported(_ pluginName: String, minimumVersion: String) async -> Bool {
        await withCheckedContinuation { continuation in
            let action = SystemStatusAction.fetchSystemPlugin(siteID: siteID, systemPluginName: pluginName) { plugin in
                // Plugin must be installed and active
                guard let plugin, plugin.active else {
                    return continuation.resume(returning: false)
                }

                // Checking for concrete versions to cover dev and beta versions
                if plugin.version.contains(minimumVersion) {
                    return continuation.resume(returning: true)
                }

                // If plugin version is higher than minimum required version, mark as eligible
                let isSupported = VersionHelpers.isVersionSupported(version: plugin.version,
                                                                    minimumRequired: minimumVersion)
                continuation.resume(returning: isSupported)
            }
            stores.dispatch(action)
        }
    }
}

private extension ReceiptEligibilityUseCase {
    enum Constants {
        static let wcPluginName = "WooCommerce"

        enum BackendReceipt {
            static let wcPluginMinimumVersion = "8.7.0"
            static let wcPluginDevVersion: [String] = ["8.7.0-dev", "8.6.0-dev"]
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
