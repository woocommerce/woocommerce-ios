import Foundation
import Yosemite

protocol CardPresentConfigurationProtocol {
    var configuration: CardPresentPaymentsConfiguration { get }
}

final class CardPresentConfigurationLoader: CardPresentConfigurationProtocol {
    init(stores: StoresManager = ServiceLocator.stores) {
        // This initializer is kept since this is where we'd check for
        // feature flags while developing support for a new country
        // See https://github.com/woocommerce/woocommerce-ios/pull/6954
    }

    var configuration: CardPresentPaymentsConfiguration {
        .init(
            country: SiteAddress().countryCode
        )
    }
}
