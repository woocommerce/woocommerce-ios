import Foundation
import enum Yosemite.SystemStatusAction
import protocol Yosemite.StoresManager
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
        guard featureFlagService.isFeatureFlagEnabled(.inbox) else {
            return completion(false)
        }

        // Fetches WC plugin.
        let action = SystemStatusAction.fetchSystemPlugin(siteID: siteID, systemPluginName: Constants.wcPluginName) { wcPlugin in
            // WooCommerce plugin is expected to be active in order to use the app/inbox.
            guard let wcPlugin = wcPlugin, wcPlugin.active else {
                return completion(false)
            }

            let isInboxSupportedByWCPlugin = VersionHelpers.isVersionSupported(version: wcPlugin.version,
                                                                               minimumRequired: Constants.wcPluginMinimumVersion)
            completion(isInboxSupportedByWCPlugin)
        }
        stores.dispatch(action)
    }

    @MainActor
    func isEligibleForInbox(siteID: Int64) async -> Bool {
        await withCheckedContinuation { [weak self] continuation in
            guard let self else {
                return continuation.resume(returning: false)
            }
            isEligibleForInbox(siteID: siteID) { isEligible in
                continuation.resume(returning: isEligible)
            }
        }
    }
}

private extension InboxEligibilityUseCase {
    enum Constants {
        static let wcPluginName = "WooCommerce"
        // TODO: 6148 - Update the minimum WC version with inbox filtering.
        static let wcPluginMinimumVersion = "5.0.0"
    }
}
