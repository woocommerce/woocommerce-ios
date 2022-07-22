@testable import WooCommerce
import Yosemite

final class MockCardPresentConfigurationLoader: CardPresentConfigurationProtocol {
    var configuration: CardPresentPaymentsConfiguration {
        .init(
            country: SiteAddress().countryCode
        )
    }
}
