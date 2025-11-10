import Foundation

public final class CIABEligibilityChecker {
    public typealias ObtainSiteClosure = () -> Site?

    public let currentSite: ObtainSiteClosure

    public init(currentSite: @escaping ObtainSiteClosure) {
        self.currentSite = currentSite
    }
}

extension CIABEligibilityChecker: CIABEligibilityCheckerProtocol {
    public var isCurrentSiteCIAB: Bool {
        guard let currentSite = currentSite() else {
            return false
        }
        return isSiteCIAB(currentSite)
    }

    public func isSiteCIAB(_ site: Site) -> Bool {
        return site.isCIAB
    }

    public func isFeatureSupportedForCurrentSite(_ feature: CIABAffectedFeature) -> Bool {
        return !isCurrentSiteCIAB || !CIABAffectedFeature.unsupportedFeatures.contains(feature)
    }

    public func isFeatureSupported(
        _ feature: CIABAffectedFeature,
        for site: Site
    ) -> Bool {
        return !isSiteCIAB(site) || !CIABAffectedFeature.unsupportedFeatures.contains(feature)
    }
}

// MARK: - Site checks

private extension Site {
    var isCIAB: Bool {
        return isGarden && gardenName == GardenName.commerce.rawValue
    }
}

private enum GardenName: String {
    /// Garden name for CIAB sites
    case commerce
}
