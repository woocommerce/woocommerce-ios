import Foundation
import UIKit
import protocol Experiments.FeatureFlagService
import struct Yosemite.Site
import protocol Yosemite.POSEligibilityServiceProtocol
import class Yosemite.POSEligibilityService

final class POSTabVisibilityChecker: POSTabVisibilityCheckerProtocol {
    private let site: Site
    private let userInterfaceIdiom: UIUserInterfaceIdiom
    private let eligibilityService: POSEligibilityServiceProtocol
    private let featureFlagService: FeatureFlagService

    init(site: Site,
         userInterfaceIdiom: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom,
         eligibilityService: POSEligibilityServiceProtocol = POSEligibilityService(),
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        self.site = site
        self.userInterfaceIdiom = userInterfaceIdiom
        self.eligibilityService = eligibilityService
        self.featureFlagService = featureFlagService
    }

    /// Checks the initial visibility of the POS tab without dependance on network requests.
    func checkInitialVisibility() -> Bool {
        eligibilityService.loadCachedPOSTabVisibility(siteID: site.siteID) ?? false
    }

    /// Checks the initial visibility without the `POSTabVisibilityChecker` instance
    /// Used for the initial state check when a site instance hasn't been loaded but a `siteID` is available
    static func checkInitialVisibility(
        for siteID: Int64,
        eligibilityService: POSEligibilityServiceProtocol = POSEligibilityService()
    ) -> Bool {
        return eligibilityService.loadCachedPOSTabVisibility(siteID: siteID) ?? false
    }

    /// Checks the final visibility of the POS tab.
    ///
    /// POS is universally available worldwide — no country, currency, or
    /// `pointOfSale` feature-flag gate. The only remaining checks are device idiom
    /// (tablet, or phone with the still-in-alpha `pointOfSalePhonePrototype` flag)
    /// and the WC plugin / feature-switch eligibility handled separately by
    /// `POSTabEligibilityChecker` once the merchant taps the tab.
    func checkVisibility() async -> Bool {
        let phonePrototypeEnabled = featureFlagService.isFeatureFlagEnabled(.pointOfSalePhonePrototype)
        return userInterfaceIdiom == .pad || phonePrototypeEnabled
    }
}
