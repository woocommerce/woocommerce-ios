import Yosemite
import Storage

final class ProductPasswordEligibilityUseCase {
    private let stores: StoresManager
    private let storageManager: StorageManagerType

    private var siteID: Int64 {
        stores.sessionManager.defaultStoreID ?? 0
    }

    init(stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager) {
        self.stores = stores
        self.storageManager = storageManager
    }

    /// In WooCommerce 8.1, the REST API now includes a new field in the products response for managing visibility passwords.
    /// This enables mobile apps to support this feature when accessing the site with Application Passwords.
    /// https://github.com/woocommerce/woocommerce/pull/39438
    func isEligibleForNewPasswordEndpoint() -> Bool {

        guard let wcPlugin = getSystemPlugin(siteID: siteID) else {
            return false
        }

        // 1. WooCommerce must be installed and active
        guard wcPlugin.active else {
            return false
        }

        // 2. If WooCommerce version is equal or higher than minimum required version, mark as eligible
        guard VersionHelpers.isVersionSupported(version: wcPlugin.version,
                                                minimumRequired: Constants.wcPluginMinimumVersion) else {
            return false
        }

        return true
    }

    /// Get the WooCommerce plugin from the current stored plugins.
    ///
    private func getSystemPlugin(siteID: Int64) -> Yosemite.SystemPlugin? {
        return storageManager.viewStorage
            .loadSystemPlugins(siteID: siteID).map { $0.toReadOnly() }
            .first(where: { $0.name == Constants.wcPluginName })
    }
}

private extension ProductPasswordEligibilityUseCase {
    enum Constants {
        static let wcPluginName = "WooCommerce"
        static let wcPluginMinimumVersion = "8.1.0"
    }
}
