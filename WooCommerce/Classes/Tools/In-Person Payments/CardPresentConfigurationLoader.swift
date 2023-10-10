import Foundation
import Yosemite
import WooFoundation

final class CardPresentConfigurationLoader {
    init(stores: StoresManager = ServiceLocator.stores) {
        // This initializer is kept since this is where we'd check for
        // feature flags while developing support for a new country
        // See https://github.com/woocommerce/woocommerce-ios/pull/6954
    }

    var configuration: CardPresentPaymentsConfiguration {
        // The `.unknown` country avoids us unwrapping an optional everywhere.
        // The configuration it results in will not support any card payments.
        guard let countryCode = CountryCode(rawValue: SiteAddress().countryCode) else {
            DDLogError("⛔️ Could not determine card payment configuration for country \(SiteAddress().countryCode)")
            return .init(country: .unknown)
        }

        return .init(
            country: countryCode
        )
    }
}
