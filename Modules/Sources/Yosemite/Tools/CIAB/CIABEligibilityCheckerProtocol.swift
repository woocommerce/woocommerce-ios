import Foundation

/// periphery: ignore
public protocol CIABEligibilityCheckerProtocol {
    var isCurrentSiteCIAB: Bool { get }
    var isCurrentSiteCIABProPlan: Bool { get }

    func isSiteCIAB(_ site: Site) -> Bool

    func isFeatureSupportedForCurrentSite(_ feature: CIABAffectedFeature) -> Bool
    func isFeatureSupported(_ feature: CIABAffectedFeature, for site: Site) -> Bool
}

public extension CIABEligibilityCheckerProtocol {
    /// Whether IPP should be hidden for the current site.
    /// True when the site is CIAB but not on a Pro plan.
    var isIPPHiddenForCurrentSite: Bool {
        isCurrentSiteCIAB && !isCurrentSiteCIABProPlan
    }
}
