import Foundation
import Yosemite

final class CardPresentConfigurationLoader {
    init(stores: StoresManager = ServiceLocator.stores) {
        // This initialized is kept since this is where we'd check for
        // feature flags while developing support for a new country
        // See https://github.com/woocommerce/woocommerce-ios/pull/6954
    }

    var configuration: CardPresentPaymentsConfiguration {
        .init(
            country: SiteAddress().countryCode
        )
    }
}
