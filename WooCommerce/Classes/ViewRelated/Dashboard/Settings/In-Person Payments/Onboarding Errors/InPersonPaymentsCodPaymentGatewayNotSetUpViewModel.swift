import Foundation
import Yosemite

struct InPersonPaymentsCodPaymentGatewayNotSetUpViewModel {
    let completion: () -> ()
    private let stores: StoresManager = ServiceLocator.stores

    private var siteID: Int64? {
        stores.sessionManager.defaultStoreID
    }

    func skipTapped() {
        guard let siteID = siteID else {
            return completion()
        }

        let action = AppSettingsAction.setSkippedCashOnDeliveryOnboardingStep(siteID: siteID)
        stores.dispatch(action)
        completion()
    }
}
