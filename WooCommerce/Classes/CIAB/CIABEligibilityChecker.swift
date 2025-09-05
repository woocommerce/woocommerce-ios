/// periphery: ignore:all - Will be used in upcoming PRs

import Foundation
import Yosemite

protocol CIABEligibilityCheckerProtocol {
    var isCurrentSiteCIAB: Bool { get }

    func isSiteCIAB(_ site: Site) -> Bool

    func isFeatureSupportedForCurrentSite(_ feature: CIABAffectedFeature) -> Bool
    func isFeatureSupported(_ feature: CIABAffectedFeature, for site: Site) -> Bool
}

final class CIABEligibilityChecker {
    private let stores: StoresManager

    init(stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
    }
}

extension CIABEligibilityChecker: CIABEligibilityCheckerProtocol {
    var isCurrentSiteCIAB: Bool {
        /// Temp mocked value
        return true
    }

    func isSiteCIAB(_ site: Site) -> Bool {
        /// Temp mocked value
        return true
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
