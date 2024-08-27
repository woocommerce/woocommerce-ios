import Foundation
import enum Yosemite.SystemStatusAction
import protocol Yosemite.StoresManager
import struct Yosemite.SystemPlugin
import Experiments

/// Checks whether a store is eligible for Inbox feature.
/// Since mobile requires API support for filtering, only stores with a minimum WC plugin version are eligible.
///
protocol InboxEligibilityChecker {

    /// Asynchronously determines whether the store is eligible for inbox feature.
    /// - Parameters:
    ///   - siteID: the ID of the site to check for Inbox eligibility.
    ///
    func isEligibleForInbox(siteID: Int64) -> Bool

}

/// Default implementation to check whether a store is eligible for Inbox feature.
///
final class InboxEligibilityUseCase: InboxEligibilityChecker {
    private let featureFlagService: FeatureFlagService

    init(featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        self.featureFlagService = featureFlagService
    }

    func isEligibleForInbox(siteID: Int64) -> Bool {
        featureFlagService.isFeatureFlagEnabled(.inbox)
    }
}
