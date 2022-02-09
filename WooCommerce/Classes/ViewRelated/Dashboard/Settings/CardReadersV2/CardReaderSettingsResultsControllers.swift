import Foundation
import Yosemite
import protocol Storage.StorageManagerType

/// Results controllers used to render the card reader settings views
///
final class CardReaderSettingsResultsControllers {
    private let storageManager: StorageManagerType

    private let siteID: Int64

    /// Completion handler for when results controllers reload.
    ///
    var onReload: (() -> Void)?

    /// PaymentGatewayAccount Results Controller.
    ///
    private lazy var paymentGatewayAccountResultsController: ResultsController<StoragePaymentGatewayAccount> = {
        let predicate = NSPredicate(format: "siteID = %ld", self.siteID)
        return ResultsController<StoragePaymentGatewayAccount>(storageManager: storageManager, matching: predicate, sortedBy: [])
    }()

    init(siteID: Int64,
         storageManager: StorageManagerType = ServiceLocator.storageManager) {
        self.siteID = siteID
        self.storageManager = storageManager
    }

    func configureResultsControllers(onReload: @escaping () -> Void) {
        self.onReload = onReload
        configurePaymentGatewayAccountResultsController(onReload: onReload)
    }

    private func configurePaymentGatewayAccountResultsController(onReload: @escaping () -> Void) {
        paymentGatewayAccountResultsController.onDidChangeContent = {
            onReload()
        }

        paymentGatewayAccountResultsController.onDidResetContent = { [weak self] in
            guard let self = self else {
                return
            }

            self.refetchAllResultsControllers()
            onReload()
        }

        try? paymentGatewayAccountResultsController.performFetch()
    }

    /// Refetching all the results controllers is necessary after a storage reset in `onDidResetContent` callback and before reloading UI that
    /// involves more than one results controller.
    func refetchAllResultsControllers() {
        try? paymentGatewayAccountResultsController.performFetch()
    }

    /// Payment Gateway Accounts for the Site (i.e. that can be used to collect payment for an order)
    var paymentGatewayAccounts: [PaymentGatewayAccount] {
        return paymentGatewayAccountResultsController.fetchedObjects
    }
}
