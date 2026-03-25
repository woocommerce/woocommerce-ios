import Foundation

/// periphery: ignore
public protocol CIABEligibilityCheckerProtocol {
    var isCurrentSiteCIAB: Bool { get }
    var isCurrentSiteCIABProPlan: Bool { get }

    func isSiteCIAB(_ site: Site) -> Bool

    func isFeatureSupportedForCurrentSite(_ feature: CIABAffectedFeature) -> Bool
    func isFeatureSupported(_ feature: CIABAffectedFeature, for site: Site) -> Bool
}
