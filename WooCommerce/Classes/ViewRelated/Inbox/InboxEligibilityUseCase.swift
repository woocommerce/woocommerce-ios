import Foundation
import enum Yosemite.SystemStatusAction
import protocol Yosemite.StoresManager
import Experiments

final class InboxEligibilityUseCase {
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
        let action = SystemStatusAction.fetchSystemPlugin(siteID: siteID, systemPluginName: Constants.wcPluginName) { [weak self] wcPlugin in
            guard let self = self else { return }

            // WooCommerce plugin is expected to be active in order to use the app/inbox.
            guard let wcPlugin = wcPlugin, wcPlugin.active else {
                return completion(false)
            }

            // Fetches WC Admin plugin. When WC Admin is active, WC Admin overrides the bundled version in WC plugin.
            let action = SystemStatusAction.fetchSystemPlugin(siteID: siteID, systemPluginName: Constants.wcAdminPluginName) { wcAdminPlugin in
                guard let wcAdminPlugin = wcAdminPlugin, wcAdminPlugin.active else {
                    let isInboxSupportedForWCPlugin = VersionHelpers.isVersionSupported(version: wcPlugin.version,
                                                                                        minimumRequired: Constants.wcPluginMinimumVersion)
                    return completion(isInboxSupportedForWCPlugin)
                }

                let isInboxSupportedForWCAdminPlugin = VersionHelpers.isVersionSupported(version: wcAdminPlugin.version,
                                                                                         minimumRequired: Constants.wcAdminPluginMinimumVersion)
                completion(isInboxSupportedForWCAdminPlugin)
            }
            self.stores.dispatch(action)
        }
        stores.dispatch(action)
    }
}

private extension InboxEligibilityUseCase {
    enum Constants {
        static let wcPluginName = "WooCommerce"
        // TODO: 6148 - Update the minimum WC version with inbox filtering.
        static let wcPluginMinimumVersion = "5.0.0"
        static let wcAdminPluginName = "WooCommerce Admin"
        // TODO: 6148 - Update the minimum WC Admin version with inbox filtering.
        static let wcAdminPluginMinimumVersion = "2.0.0"
    }
}
