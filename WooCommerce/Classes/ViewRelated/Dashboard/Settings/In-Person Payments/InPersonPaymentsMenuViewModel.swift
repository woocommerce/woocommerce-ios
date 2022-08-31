import Foundation
import Yosemite

class InPersonPaymentsMenuViewModel: ObservableObject {
    let stores: StoresManager

    @Published var cashOnDeliveryEnabledState: Bool = false

    var siteID: Int64? {
        stores.sessionManager.defaultStoreID
    }

    private lazy var paymentGatewaysFetchedResultsController: ResultsController<StoragePaymentGateway>? = {
        guard let siteID = siteID else {
            return nil
        }

        let predicate = NSPredicate(format: "siteID == %lld", siteID)

        return ResultsController<StoragePaymentGateway>(storageManager: ServiceLocator.storageManager,
                                                        matching: predicate,
                                                        sortedBy: [])
    }()

    init(stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
        observePaymentGateways()
    }

    private func observePaymentGateways() {
        guard let paymentGatewaysFetchedResultsController = paymentGatewaysFetchedResultsController else {
            return
        }
        paymentGatewaysFetchedResultsController.onDidChangeContent = updateCashOnDeliveryEnabledState
        paymentGatewaysFetchedResultsController.onDidResetContent = updateCashOnDeliveryEnabledState
        do {
            try paymentGatewaysFetchedResultsController.performFetch()
            updateCashOnDeliveryEnabledState()
        } catch {
            ServiceLocator.crashLogging.logError(error)
        }
    }

    private func updateCashOnDeliveryEnabledState() {
        let codGateway = paymentGatewaysFetchedResultsController?.fetchedObjects.first(where: { $0.gatewayID == "cod" })
        cashOnDeliveryEnabledState = codGateway?.enabled ?? false
    }
}
