import Foundation
import Yosemite
import WooFoundation

final class CardPresentConfigurationLoader {
    private let stores: StoresManager
    private let eligibilityService: CardPresentPaymentsCountryExpansionEligibilityServiceProtocol

    init(stores: StoresManager = ServiceLocator.stores,
         eligibilityService: CardPresentPaymentsCountryExpansionEligibilityServiceProtocol = CardPresentPaymentsCountryExpansionEligibilityService()) {
        // The `stores` parameter is kept since this is where we'd check for
        // feature flags while developing support for a new country
        // See https://github.com/woocommerce/woocommerce-ios/pull/6954
        self.stores = stores
        self.eligibilityService = eligibilityService
    }

    var configuration: CardPresentPaymentsConfiguration {
        // The `.unknown` country avoids us unwrapping an optional everywhere.
        // The configuration it results in will not support any card payments.
        let countryCode = SiteAddress().countryCode

        // RSM-637: gate the country expansion behind a per-site eligibility cache.
        // When the country requires the expansion flag and the site isn't yet eligible,
        // surface as an unsupported country so the existing IPP entry points (which all
        // gate on `isSupportedCountry`) hide downstream.
        // When the flag is removed, delete this guard and the `flag(for:)` lookup; the
        // configuration will return the country's normal config unconditionally.
        if let _ = CardPresentPaymentsCountryExpansionEligibilityRefresher.flag(for: countryCode),
           let siteID = stores.sessionManager.defaultStoreID,
           !eligibilityService.isEligible(siteID: siteID) {
            return CardPresentPaymentsConfiguration(country: .unknown)
        }

        return .init(country: countryCode)
    }
}
