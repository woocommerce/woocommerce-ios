import Foundation
import Storage

/// Protocol defining the interface for the In-Person Payments country expansion
/// eligibility service (RSM-637).
///
/// Provides synchronous reads of a per-site cached boolean answering "is this site
/// allowed to expose IPP based on its country and the relevant remote feature flag".
public protocol CardPresentPaymentsCountryExpansionEligibilityServiceProtocol {
    /// Returns the cached eligibility for a given site. Defaults to `false` until the
    /// refresher has run for the first time.
    func isEligible(siteID: Int64) -> Bool

    /// Persists the latest eligibility for a given site. Reads from
    /// ``isEligible(siteID:)`` will reflect the new value on subsequent launches.
    func cacheEligibility(siteID: Int64, isEligible: Bool)
}

public final class CardPresentPaymentsCountryExpansionEligibilityService: CardPresentPaymentsCountryExpansionEligibilityServiceProtocol {
    private let siteSpecificAppSettingsStoreMethods: SiteSpecificAppSettingsStoreMethodsProtocol

    public convenience init() {
        self.init(siteSpecificAppSettingsStoreMethods: SiteSpecificAppSettingsStoreMethods(fileStorage: PListFileStorage()))
    }

    init(siteSpecificAppSettingsStoreMethods: SiteSpecificAppSettingsStoreMethodsProtocol) {
        self.siteSpecificAppSettingsStoreMethods = siteSpecificAppSettingsStoreMethods
    }

    public func isEligible(siteID: Int64) -> Bool {
        siteSpecificAppSettingsStoreMethods.loadCardPresentPaymentsCountryExpansionEligibility(siteID: siteID) ?? false
    }

    public func cacheEligibility(siteID: Int64, isEligible: Bool) {
        siteSpecificAppSettingsStoreMethods.saveCardPresentPaymentsCountryExpansionEligibility(siteID: siteID, isEligible: isEligible)
    }
}
