import Yosemite
import Experiments
import protocol Storage.StorageManagerType

final class OrderSalesChannelEligibilityChecker {
    private let featureFlagService: FeatureFlagService
    private let storageManager: StorageManagerType

    init(featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         storageManager: StorageManagerType = ServiceLocator.storageManager) {
        self.featureFlagService = featureFlagService
        self.storageManager = storageManager
    }

    func performEligibilityCheck(siteID: Int64) async -> Bool {
        guard checkFeatureFlagEligibility(), await checkPluginEligibility(siteID: siteID) else {
            return false
        }
        return true
    }

    private func checkPluginEligibility(siteID: Int64) async -> Bool {
        let pluginsService = PluginsService(storageManager: storageManager)
        let wcPlugin = await pluginsService.waitForPluginInStorage(siteID: siteID,
                                                                   pluginName: Constants.pluginName,
                                                                   isActive: true)
        guard VersionHelpers.isVersionSupported(version: wcPlugin.version, minimumRequired: Constants.pluginMinimumVersion) else {
            return false
        }
        return true
    }

    private func checkFeatureFlagEligibility() -> Bool {
        featureFlagService.isFeatureFlagEnabled(.pointOfSaleOrdersi1)
    }
}

private extension OrderSalesChannelEligibilityChecker {
    enum Constants {
        static let pluginName = "WooCommerce"
        static let pluginMinimumVersion = "9.9.0"
    }
}
