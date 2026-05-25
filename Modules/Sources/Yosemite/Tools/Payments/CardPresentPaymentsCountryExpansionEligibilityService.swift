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
        // Broadcast so live consumers (POS card-payment gate, IPP entry points)
        // re-evaluate their cached read of `CardPresentConfigurationLoader` — the
        // loader's `configuration` accessor calls back into `isEligible(siteID:)`
        // synchronously, so refreshing on this notification picks up the new value.
        // Cold-start race fix for expansion-flag-gated countries (Spain / FR / DE /
        // AU / NZ / SG …) whose configuration arrives after the POS tab first renders.
        NotificationCenter.default.post(
            name: .cardPresentPaymentsCountryExpansionEligibilityDidChange,
            object: nil,
            userInfo: [Self.siteIDKey: siteID]
        )
    }

    /// `userInfo` key whose value is the `Int64` siteID whose eligibility was updated.
    public static let siteIDKey = "siteID"
}

public extension Notification.Name {
    /// Posted on `NotificationCenter.default` after
    /// ``CardPresentPaymentsCountryExpansionEligibilityServiceProtocol/cacheEligibility(siteID:isEligible:)``
    /// writes a new value. `userInfo[CardPresentPaymentsCountryExpansionEligibilityService.siteIDKey]`
    /// carries the affected siteID as `Int64`. Consumers should re-read whatever
    /// they derive from `CardPresentConfigurationLoader` (POS card-payment gate,
    /// IPP entry-point gates) when this fires.
    static let cardPresentPaymentsCountryExpansionEligibilityDidChange = Notification.Name(
        rawValue: "com.woocommerce.ios.cardPresentPaymentsCountryExpansionEligibilityDidChange"
    )
}
