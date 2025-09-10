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
        guard let currentSite = stores.sessionManager.defaultSite else {
            return false
        }
        return isSiteCIAB(currentSite)
    }

    func isSiteCIAB(_ site: Site) -> Bool {
        /// Temp logic
        /// If site name contains either `garden` or `ciab` then it's considered a CIAB site
        return isCIABSupportedForBuildEnvironment && CIABUnlockingSiteNameSubstrings.allCases.contains {
            site.name.lowercased().contains($0.rawValue)
        }
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

// MARK: - Temporary constants for CIAB identifying logic

fileprivate extension CIABEligibilityChecker {
    enum CIABUnlockingSiteNameSubstrings: String, CaseIterable {
        case garden
        case ciab
    }
}

// MARK: - Temporary environment checks

import enum WooFoundationCore.BuildConfiguration

private extension CIABEligibilityChecker {
    var isCIABSupportedForBuildEnvironment: Bool {
        let buildConfig = BuildConfiguration.current
        return buildConfig == .localDeveloper || buildConfig == .alpha
    }
}
