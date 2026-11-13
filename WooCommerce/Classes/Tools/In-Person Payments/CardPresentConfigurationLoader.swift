import Foundation
import Yosemite
import WooFoundation

final class CardPresentConfigurationLoader {
    var configuration: CardPresentPaymentsConfiguration {
        // The `.unknown` country avoids us unwrapping an optional everywhere.
        // The configuration it results in will not support any card payments.
        let countryCode = SiteAddress().countryCode

        return .init(country: countryCode)
    }
}
