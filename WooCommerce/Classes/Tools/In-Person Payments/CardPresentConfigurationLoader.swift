import Foundation
import Yosemite

final class CardPresentConfigurationLoader {
    private var canadaIPPEnabled: Bool = false

    init(stores: StoresManager = ServiceLocator.stores) {
        let canadaAction = AppSettingsAction.loadCanadaInPersonPaymentsSwitchState(onCompletion: { [weak self]  result in
            if case .success(let canadaIPPEnabled) = result {
                self?.canadaIPPEnabled = canadaIPPEnabled
            }
        })
        stores.dispatch(canadaAction)
    }

    var configuration: CardPresentPaymentsConfiguration {
        .init(
            country: SiteAddress().countryCode,
            canadaEnabled: canadaIPPEnabled
        )
    }
}
