import Yosemite
import Experiments

protocol ReceiptEligibilityUseCaseProtocol {
    func isEligibleForBackendReceipts(onCompletion: @escaping (Bool) -> Void)
    func isEligibleSendingReceiptAfterPayment(onCompletion: @escaping (Bool) -> Void)
}

final class ReceiptEligibilityUseCase: ReceiptEligibilityUseCaseProtocol {
    private let stores: StoresManager
    private let featureFlagService: FeatureFlagService

    private var siteID: Int64 {
        stores.sessionManager.defaultStoreID ?? 0
    }

    init(stores: StoresManager = ServiceLocator.stores,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        self.stores = stores
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

    func isEligibleForPointOfSaleReceipts(onCompletion: @escaping (Bool) -> Void) {
        guard featureFlagService.isFeatureFlagEnabled(.sendReceiptsForPointOfSale) else {
            onCompletion(false)
            return
        }

        Task { @MainActor in
            async let isWooCommerceSupported = isPluginSupported(Constants.wcPluginName,
                                                                 minimumVersion: Constants.PointOfSaleReceipts.wcPluginMinimumVersion)
            let wooCommerceResult = await isWooCommerceSupported
            onCompletion(wooCommerceResult)
        }
    }

    func isEligibleSendingReceiptAfterPayment(onCompletion: @escaping (Bool) -> Void) {
        guard featureFlagService.isFeatureFlagEnabled(.sendReceiptAfterPayment) else {
            return onCompletion(false)
        }

        Task { @MainActor in
            async let isWooCommerceSupported = isPluginSupported(Constants.wcPluginName,
                                                                 minimumVersion: Constants.ReceiptAfterPayment.wcPluginMinimumVersion)
            async let isWooPaymentsSupported = isPluginSupported(Constants.wcPayPluginName,
                                                                 minimumVersion: Constants.ReceiptAfterPayment.wcPayPluginMinimumVersion)
            let wooCommerceResult = await isWooCommerceSupported
            let wooPaymentsResult = await isWooPaymentsSupported
            let isSupported = wooCommerceResult && wooPaymentsResult

            onCompletion(isSupported)
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
        static let wcPayPluginName = "WooPayments"

        enum BackendReceipt {
            static let wcPluginMinimumVersion = "8.7.0"
            static let wcPluginDevVersion: [String] = ["8.7.0-dev", "8.6.0-dev"]
        }

        enum ReceiptAfterPayment {
            static let wcPluginMinimumVersion = "9.5.0"
            static let wcPayPluginMinimumVersion = "8.6.0"
        }

        enum PointOfSaleReceipts {
            static let wcPluginMinimumVersion = "9.5.0"
        }
    }
}
