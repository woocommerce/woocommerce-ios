import Foundation
import Experiments
import Yosemite
import class WooFoundation.VersionHelpers

/// Interface for checking if a site is eligible for creating Google ads campaigns from the app.
///
protocol GoogleAdsEligibilityChecker {
    @MainActor
    func isSiteEligible(siteID: Int64) async -> Bool
}

final class DefaultGoogleAdsEligibilityChecker: GoogleAdsEligibilityChecker {

    private let stores: StoresManager
    private let featureFlagService: FeatureFlagService

    /// In-flight eligibility checks keyed by siteID, shared across all instances.
    /// Thread-safe because all access is on @MainActor.
    private static var inFlightChecks: [Int64: Task<Bool, Never>] = [:]

    init(stores: StoresManager = ServiceLocator.stores,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        self.stores = stores
        self.featureFlagService = featureFlagService
    }

    @MainActor
    func isSiteEligible(siteID: Int64) async -> Bool {
        if let existingTask = Self.inFlightChecks[siteID] {
            return await existingTask.value
        }

        let task = Task { @MainActor [weak self] () -> Bool in
            guard let self else { return false }
            return await self.performEligibilityCheck(siteID: siteID)
        }
        Self.inFlightChecks[siteID] = task
        let result = await task.value
        Self.inFlightChecks.removeValue(forKey: siteID)
        return result
    }

    @MainActor
    private func performEligibilityCheck(siteID: Int64) async -> Bool {
        guard featureFlagService.isFeatureFlagEnabled(.googleAdsCampaignCreationOnWebView) else {
            return false
        }

        do {
            let connection = try await checkGoogleAdsConnection(siteID: siteID)
            guard connection.status == .connected else {
                return false
            }
        } catch {
            DDLogError("⛔️ Error checking Google ads connection: \(error)")
            return false
        }

        /// Ensures that the plugin is running the correct version.
        let remotePlugin = await fetchPluginFromRemote(siteID: siteID)
        return checkIfGoogleAdsIsSupported(plugin: remotePlugin)
    }
}

private extension DefaultGoogleAdsEligibilityChecker {
    @MainActor
    func fetchPluginFromRemote(siteID: Int64) async -> SystemPlugin? {
        await withCheckedContinuation { continuation in
            stores.dispatch(SystemStatusAction.synchronizeSystemInformation(siteID: siteID) { result in
                switch result {
                case .success(let info):
                    let plugin = info.systemPlugins.first(where: { Plugin(systemPlugin: $0) == .googleListingsAndAds && $0.active })
                    continuation.resume(returning: plugin)
                case .failure:
                    continuation.resume(returning: nil)
                }
            })
        }
    }

    func checkIfGoogleAdsIsSupported(plugin: SystemPlugin?) -> Bool {
        guard let plugin, plugin.active else {
            return false
        }
        return VersionHelpers.isVersionSupported(version: plugin.version,
                                                 minimumRequired: Constants.pluginMinimumVersion)
    }

    @MainActor
    func checkGoogleAdsConnection(siteID: Int64) async throws -> GoogleAdsConnection {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(GoogleAdsAction.checkConnection(siteID: siteID, onCompletion: { result in
                continuation.resume(with: result)
            }))
        }
    }

    enum Constants {
        /// Version 2.7.7 is required for an optimized experience of the plugin on the mobile web.
        /// Ref: https://github.com/woocommerce/google-listings-and-ads/releases/tag/2.7.7.
        /// We can remove this limit once we support native experience.
        static let pluginMinimumVersion = "2.7.7"
    }
}
