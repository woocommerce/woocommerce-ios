import Foundation
import Yosemite

final class InPersonPaymentsMenuViewModel {
    private let stores: StoresManager

    private var siteID: Int64? {
        return stores.sessionManager.defaultStoreID
    }

    init(stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
    }

    func viewDidLoad() {
        guard let siteID = siteID else {
            return
        }

        let action = PaymentGatewayAction.synchronizePaymentGateways(siteID: siteID, onCompletion: { _ in })
        stores.dispatch(action)
    }
}
