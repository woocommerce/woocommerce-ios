import Foundation
import Yosemite

/// periphery: ignore - Will be used in upcoming changes for app feature gating
protocol CIABEligibilityCheckerProtocol {
    var isCurrentSiteCIAB: Bool { get }

    func isSiteCIAB(_ site: Site) -> Bool

    func isFeatureSupportedForCurrentSite(_ feature: CIABAffectedFeature) -> Bool
    func isFeatureSupported(_ feature: CIABAffectedFeature, for site: Site) -> Bool
}
