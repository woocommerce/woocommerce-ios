import Foundation
import Yosemite

final class CIABEligibilityChecker {
    private let stores: StoresManager

    init(stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
    }
}

extension CIABEligibilityChecker: CIABEligibilityCheckerProtocol {
    var isCurrentSiteCIAB: Bool {
        guard let currentSite = stores.sessionManager.defaultSite else {
            return false
        }
        return isSiteCIAB(currentSite)
    }

    func isSiteCIAB(_ site: Site) -> Bool {
        return site.isCIAB
    }

    func isFeatureSupportedForCurrentSite(_ feature: CIABAffectedFeature) -> Bool {
        return !isCurrentSiteCIAB || !CIABAffectedFeature.unsupportedFeatures.contains(feature)
    }

    func isFeatureSupported(
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
