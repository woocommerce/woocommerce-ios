import Yosemite
import Experiments

final class ReceiptEligibilityUseCase {
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
            // 2. If WooCommerce version is the specific API development branch, mark as eligible
            if wcPlugin.version == Constants.wcPluginDevVersion {
                onCompletion(true)
            } else {
                // 3. Else, if WooCommerce version is higher than minimum required version, mark as eligible
                let isSupported = VersionHelpers.isVersionSupported(version: wcPlugin.version,
                                                                    minimumRequired: Constants.wcPluginMinimumVersion)
                onCompletion(isSupported)
            }
        }
        stores.dispatch(action)
    }
}

private extension ReceiptEligibilityUseCase {
    enum Constants {
        static let wcPluginName = "WooCommerce"
        static let wcPluginMinimumVersion = "8.7.0"
        static let wcPluginDevVersion = "8.6.0-dev-7625495467-gf50cc6b"
    }
}
