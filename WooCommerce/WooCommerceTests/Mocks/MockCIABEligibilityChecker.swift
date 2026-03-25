import Foundation
import Yosemite
@testable import WooCommerce

final class MockCIABEligibilityChecker: CIABEligibilityCheckerProtocol {
    private let mockedIsCurrentSiteCIAB: Bool
    private let mockedIsCurrentSiteCIABProPlan: Bool
    private let mockedCIABSites: [Site]
    private let mockedCIABDisabledFeatures: [CIABAffectedFeature]

    init(mockedIsCurrentSiteCIAB: Bool,
         mockedIsCurrentSiteCIABProPlan: Bool = false,
         mockedCIABSites: [Site] = [],
         mockedCIABDisabledFeatures: [CIABAffectedFeature] = CIABAffectedFeature.allCases) {
        self.mockedIsCurrentSiteCIAB = mockedIsCurrentSiteCIAB
        self.mockedIsCurrentSiteCIABProPlan = mockedIsCurrentSiteCIABProPlan
        self.mockedCIABSites = mockedCIABSites
        self.mockedCIABDisabledFeatures = mockedCIABDisabledFeatures
    }

    var isCurrentSiteCIAB: Bool {
        return mockedIsCurrentSiteCIAB
    }

    var isCurrentSiteCIABProPlan: Bool {
        return mockedIsCurrentSiteCIABProPlan
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
