import Foundation
import Experiments
import Yosemite

/// Interface for checking if a site is eligible for creating Google ads campaigns from the app.
///
protocol GoogleAdsEligibilityChecker {
    @MainActor
    func isSiteEligible(siteID: Int64) async -> Bool
}

final class DefaultGoogleAdsEligibilityChecker: GoogleAdsEligibilityChecker {

    private let stores: StoresManager
    private let featureFlagService: FeatureFlagService

    init(stores: StoresManager = ServiceLocator.stores, featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        self.stores = stores
        self.featureFlagService = featureFlagService
    }

    func isSiteEligible(siteID: Int64) async -> Bool {
        guard featureFlagService.isFeatureFlagEnabled(.googleAdsCampaignCreationOnWebView) else {
            return false
        }

        let isPluginSatisfied: Bool = await {
            if let savedPlugin = await fetchPluginFromStorage(siteID: siteID) {
                return checkIfGoogleAdsIsSupported(plugin: savedPlugin)
            } else {
                let remotePlugin = await fetchPluginFromRemote(siteID: siteID)
                return checkIfGoogleAdsIsSupported(plugin: remotePlugin)
            }
        }()

        return isPluginSatisfied
    }

}

private extension DefaultGoogleAdsEligibilityChecker {
    @MainActor
    func fetchPluginFromStorage(siteID: Int64) async -> SystemPlugin? {
        await withCheckedContinuation { continuation in
            stores.dispatch(SystemStatusAction.fetchSystemPluginWithPath(siteID: siteID, pluginPath: Constants.pluginSlug) { plugin in
                continuation.resume(returning: plugin)
            })
        }
    }

    @MainActor
    func fetchPluginFromRemote(siteID: Int64) async -> SystemPlugin? {
        await withCheckedContinuation { continuation in
            stores.dispatch(SystemStatusAction.synchronizeSystemInformation(siteID: siteID) { result in
                switch result {
                case .success(let info):
                    let wcPlugin = info.systemPlugins.first(where: { $0.plugin == Constants.pluginSlug })
                    continuation.resume(returning: wcPlugin)
                case .failure:
                    continuation.resume(returning: nil)
                }
            })
        }
    }

    func checkIfGoogleAdsIsSupported(plugin: SystemPlugin?) -> Bool {
        guard let plugin = plugin, plugin.active else {
            return false
        }
        return VersionHelpers.isVersionSupported(version: plugin.version,
                                                 minimumRequired: Constants.pluginMinimumVersion)
    }

    enum Constants {
        static let pluginSlug = "google-listings-and-ads/google-listings-and-ads"
        static let pluginMinimumVersion = "2.7.5"
    }
}
