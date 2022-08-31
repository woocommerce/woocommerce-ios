import Foundation
import Yosemite

class InPersonPaymentsMenuViewModel: ObservableObject {
    let stores: StoresManager

    @Published var cashOnDeliveryEnabledState: Bool = false

    private var siteID: Int64? {
        stores.sessionManager.defaultStoreID
    }

    private let paymentGatewaysFetchedResultsController: ResultsController<StoragePaymentGateway>?

    init(stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
        paymentGatewaysFetchedResultsController = Self.createPaymentGatewaysResultsController(siteID: stores.sessionManager.defaultStoreID)
        observePaymentGateways()
    }

    // MARK: - PaymentGateway observation
    private func observePaymentGateways() {
        paymentGatewaysFetchedResultsController?.onDidChangeContent = updateCashOnDeliveryEnabledState
        paymentGatewaysFetchedResultsController?.onDidResetContent = updateCashOnDeliveryEnabledState
        do {
            try paymentGatewaysFetchedResultsController?.performFetch()
            updateCashOnDeliveryEnabledState()
        } catch {
            ServiceLocator.crashLogging.logError(error)
        }
    }

    private static func createPaymentGatewaysResultsController(siteID: Int64?) -> ResultsController<StoragePaymentGateway>? {
        guard let siteID = siteID else {
            return nil
        }

        let predicate = NSPredicate(format: "siteID == %lld", siteID)

        return ResultsController<StoragePaymentGateway>(storageManager: ServiceLocator.storageManager,
                                                        matching: predicate,
                                                        sortedBy: [])
    }

    private func updateCashOnDeliveryEnabledState() {
        let codGateway = paymentGatewaysFetchedResultsController?.fetchedObjects.first(where: { $0.gatewayID == "cod" })
        cashOnDeliveryEnabledState = codGateway?.enabled ?? false
    }
}
