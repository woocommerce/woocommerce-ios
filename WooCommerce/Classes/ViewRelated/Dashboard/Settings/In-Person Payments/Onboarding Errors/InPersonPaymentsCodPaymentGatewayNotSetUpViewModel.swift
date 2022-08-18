import Foundation
import Yosemite

struct InPersonPaymentsCodPaymentGatewayNotSetUpViewModel {
    let completion: () -> ()
    let stores: StoresManager = ServiceLocator.stores

    private var siteID: Int64? {
        stores.sessionManager.defaultStoreID
    }

    func skipTapped() {
        guard let siteID = siteID else {
            return completion()
        }

        let action = AppSettingsAction.setSkippedCodOnboardingStep(siteID: siteID)
        stores.dispatch(action)
        completion()
    }

}
