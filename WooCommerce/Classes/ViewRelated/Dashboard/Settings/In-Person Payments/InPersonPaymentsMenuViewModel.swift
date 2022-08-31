import Foundation
import Yosemite

class InPersonPaymentsMenuViewModel: ObservableObject {

    // MARK: - Dependencies
    struct Dependencies {
        let stores: StoresManager
        let noticePresenter: NoticePresenter
        let analytics: Analytics

        init(stores: StoresManager = ServiceLocator.stores,
             noticePresenter: NoticePresenter = ServiceLocator.noticePresenter,
             analytics: Analytics = ServiceLocator.analytics) {
            self.stores = stores
            self.noticePresenter = noticePresenter
            self.analytics = analytics
        }
    }

    private let dependencies: Dependencies

    private var stores: StoresManager {
        dependencies.stores
    }

    private var noticePresenter: NoticePresenter {
        dependencies.noticePresenter
    }

    private var analytics: Analytics {
        dependencies.analytics
    }

    // MARK: - Output properties
    @Published var cashOnDeliveryEnabledState: Bool = false

    // MARK: - Configuration properties
    private var siteID: Int64? {
        stores.sessionManager.defaultStoreID
    }

    private let paymentGatewaysFetchedResultsController: ResultsController<StoragePaymentGateway>?

    init(dependencies: Dependencies = Dependencies()) {
        self.dependencies = dependencies
        paymentGatewaysFetchedResultsController = Self.createPaymentGatewaysResultsController(
            siteID: dependencies.stores.sessionManager.defaultStoreID)
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
        cashOnDeliveryEnabledState = cashOnDeliveryGateway?.enabled ?? false
    }

    private var cashOnDeliveryGateway: PaymentGateway? {
        paymentGatewaysFetchedResultsController?.fetchedObjects.first(where: {
            $0.gatewayID == PaymentGateway.Constants.cashOnDeliveryGatewayID
        })
    }

    // MARK: - Toggle Cash on Delivery Payment Gateway

    func updateCashOnDeliverySetting(enabled: Bool) {
    }
}
