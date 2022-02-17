import Foundation
import Yosemite

final class CardPresentConfigurationLoader {
    private var stripeGatewayIPPEnabled: Bool = false
    private var canadaIPPEnabled: Bool = false

    init(stores: StoresManager = ServiceLocator.stores) {
        let stripeAction = AppSettingsAction.loadStripeInPersonPaymentsSwitchState(onCompletion: { [weak self] result in
            if case .success(let stripeGatewayIPPEnabled) = result {
                self?.stripeGatewayIPPEnabled = stripeGatewayIPPEnabled
            }
        })
        stores.dispatch(stripeAction)

        let canadaAction = AppSettingsAction.loadCanadaInPersonPaymentsSwitchState(onCompletion: { [weak self]  result in
            switch result {
            case .success(let canadaIPPEnabled):
                self?.canadaIPPEnabled = canadaIPPEnabled
            default:
                break
            }
        })
        stores.dispatch(canadaAction)
    }

    var configuration: CardPresentPaymentsConfiguration {
        .init(
            country: SiteAddress().countryCode,
            stripeEnabled: stripeGatewayIPPEnabled,
            canadaEnabled: canadaIPPEnabled
        )
    }
}
