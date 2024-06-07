import Foundation
import enum Yosemite.SystemStatusAction
import protocol Yosemite.StoresManager
import struct Yosemite.SystemPlugin
import Experiments

/// Checks whether a store is eligible for Inbox feature.
/// Since mobile requires API support for filtering, only stores with a minimum WC plugin version are eligible.
///
protocol InboxEligibilityChecker {
    /// Determines whether the store is eligible for inbox feature.
    /// - Parameters:
    ///   - siteID: the ID of the site to check for Inbox eligibility.
    ///   - completion: called when the Inbox eligibility is determined.
    ///
    func isEligibleForInbox(siteID: Int64, completion: @escaping (Bool) -> Void)

    /// Asynchronously determines whether the store is eligible for inbox feature.
    /// - Parameters:
    ///   - siteID: the ID of the site to check for Inbox eligibility.
    ///
    func isEligibleForInbox(siteID: Int64) async -> Bool

}

/// Default implementation to check whether a store is eligible for Inbox feature.
///
final class InboxEligibilityUseCase: InboxEligibilityChecker {
    private let stores: StoresManager
    private let featureFlagService: FeatureFlagService

    init(stores: StoresManager = ServiceLocator.stores, featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        self.stores = stores
        self.featureFlagService = featureFlagService
    }

    /// Determines whether the store is eligible for inbox feature.
    /// - Parameters:
    ///   - siteID: the ID of the site to check for Inbox eligibility.
    ///   - completion: called when the Inbox eligibility is determined.
    func isEligibleForInbox(siteID: Int64, completion: @escaping (Bool) -> Void) {
        Task {
            let result = await isEligibleForInbox(siteID: siteID)
            completion(result)
        }
    }

    @MainActor
    func isEligibleForInbox(siteID: Int64) async -> Bool {
        guard featureFlagService.isFeatureFlagEnabled(.inbox) else {
            return false
        }

        if let savedPlugin = await fetchWooPluginFromStorage(siteID: siteID) {
            return checkIfInboxIsSupported(wcPlugin: savedPlugin)
        } else {
            let remotePlugin = await fetchWooPluginFromRemote(siteID: siteID)
            return checkIfInboxIsSupported(wcPlugin: remotePlugin)
        }
    }
}

private extension InboxEligibilityUseCase {
    @MainActor
    func fetchWooPluginFromStorage(siteID: Int64) async -> SystemPlugin? {
        await withCheckedContinuation { continuation in
            stores.dispatch(SystemStatusAction.fetchSystemPlugin(siteID: siteID, systemPluginName: Constants.wcPluginName) { plugin in
                continuation.resume(returning: plugin)
            })
        }
    }

    @MainActor
    func fetchWooPluginFromRemote(siteID: Int64) async -> SystemPlugin? {
        await withCheckedContinuation { continuation in
            stores.dispatch(SystemStatusAction.synchronizeSystemInformation(siteID: siteID) { result in
                switch result {
                case .success(let info):
                    let wcPlugin = info.systemPlugins.first(where: { $0.name == Constants.wcPluginName })
                    continuation.resume(returning: wcPlugin)
                case .failure:
                    continuation.resume(returning: nil)
                }
            })
        }
    }

    func checkIfInboxIsSupported(wcPlugin: SystemPlugin?) -> Bool {
        guard let wcPlugin = wcPlugin, wcPlugin.active else {
            return false
        }
        return VersionHelpers.isVersionSupported(version: wcPlugin.version,
                                                 minimumRequired: Constants.wcPluginMinimumVersion)
    }

    enum Constants {
        static let wcPluginName = "WooCommerce"
        // TODO: 6148 - Update the minimum WC version with inbox filtering.
        static let wcPluginMinimumVersion = "5.0.0"
    }
}
