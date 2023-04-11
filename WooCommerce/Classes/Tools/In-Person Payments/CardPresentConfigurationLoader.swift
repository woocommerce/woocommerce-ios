import Foundation
import Experiments
import Yosemite

final class CardPresentConfigurationLoader {
    let shouldReturnConfigurationForGB: Bool

    init(stores: StoresManager = ServiceLocator.stores,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        // This initializer is kept since this is where we'd check for
        // feature flags while developing support for a new country
        // See https://github.com/woocommerce/woocommerce-ios/pull/6954

        shouldReturnConfigurationForGB = featureFlagService.isFeatureFlagEnabled(.IPPUKExpansion)
    }

    var configuration: CardPresentPaymentsConfiguration {
        .init(
            country: SiteAddress().countryCode,
            shouldReturnConfigurationForGB: shouldReturnConfigurationForGB
        )
    }
}
