import Foundation
import Yosemite
@testable import WooCommerce

final class MockCIABEligibilityChecker: CIABEligibilityCheckerProtocol {
    private let mockedIsCurrentSiteCIAB: Bool
    private let mockedCIABSites: [Site]
    private let mockedCIABDisabledFeatures: [CIABAffectedFeature]

    init(mockedIsCurrentSiteCIAB: Bool,
         mockedCIABSites: [Site] = [],
         mockedCIABDisabledFeatures: [CIABAffectedFeature] = CIABAffectedFeature.allCases) {
        self.mockedIsCurrentSiteCIAB = mockedIsCurrentSiteCIAB
        self.mockedCIABSites = mockedCIABSites
        self.mockedCIABDisabledFeatures = mockedCIABDisabledFeatures
    }

    var isCurrentSiteCIAB: Bool {
        return mockedIsCurrentSiteCIAB
    }

    func isSiteCIAB(_ site: Site) -> Bool {
        return mockedCIABSites.contains(site)
    }

    func isFeatureSupportedForCurrentSite(_ feature: CIABAffectedFeature) -> Bool {
        return !mockedCIABDisabledFeatures.contains(feature) || !isCurrentSiteCIAB
    }

    func isFeatureSupported(_ feature: CIABAffectedFeature, for site: Site) -> Bool {
        return !mockedCIABDisabledFeatures.contains(feature) || !mockedCIABSites.contains(site)
    }
}
