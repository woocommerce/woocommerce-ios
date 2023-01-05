import Foundation
import Yosemite
import WooFoundation
import protocol Storage.StorageManagerType

final class InPersonPaymentsMenuViewModel {
    // MARK: - Dependencies
    struct Dependencies {
        let stores: StoresManager
        let analytics: Analytics
        let storage: StorageManagerType

        init(stores: StoresManager = ServiceLocator.stores,
             storage: StorageManagerType = ServiceLocator.storageManager,
             analytics: Analytics = ServiceLocator.analytics) {
            self.stores = stores
            self.storage = storage
            self.analytics = analytics
        }
    }

    private let dependencies: Dependencies

    private var stores: StoresManager {
        dependencies.stores
    }

    private var storage: StorageManagerType {
        dependencies.storage
    }

    private var analytics: Analytics {
        dependencies.analytics
    }

    private lazy var resultsController = createIPPOrdersResultsController()

    // MARK: - Output properties
    @Published var showWebView: AuthenticatedWebViewModel? = nil

    // MARK: - Configuration properties
    private var siteID: Int64? {
        return stores.sessionManager.defaultStoreID
    }

    private let cardPresentPaymentsConfiguration: CardPresentPaymentsConfiguration

    init(dependencies: Dependencies = Dependencies(),
         cardPresentPaymentsConfiguration: CardPresentPaymentsConfiguration = CardPresentConfigurationLoader().configuration) {
        self.dependencies = dependencies
        self.cardPresentPaymentsConfiguration = cardPresentPaymentsConfiguration

        fetchIPPTransactions()
    }

    func viewDidLoad() {
        guard let siteID = siteID else {
            return
        }

        let action = PaymentGatewayAction.synchronizePaymentGateways(siteID: siteID, onCompletion: { _ in })
        stores.dispatch(action)
    }

    func orderCardReaderPressed() {
        analytics.track(.paymentsMenuOrderCardReaderTapped)
        showWebView = PurchaseCardReaderWebViewViewModel(configuration: cardPresentPaymentsConfiguration,
                                                         utmProvider: WooCommerceComUTMProvider(
                                                            campaign: Constants.utmCampaign,
                                                            source: Constants.utmSource,
                                                            content: nil,
                                                            siteID: siteID),
                                                         onDismiss: { [weak self] in
            self?.showWebView = nil
        })
    }

    func displayResults() {
        let results = resultsController.fetchedObjects
        let resultsCount = results.count
        // Debug:
        print("IPP transactions within 30 days: \(resultsCount)")
        print(results.map { ("OrderID: \($0.orderID) - PaymentMethodID: \($0.paymentMethodID) - DatePaid: \(String(describing: $0.datePaid))") })

        if resultsCount < 10 {
            // TODO: Select banner 1
            print("< 10 transactions. Banner 1 shown")
        } else {
            // TODO: Select banner 2
            print(">= 10 transactions. Banner 2 shown")
        }
    }

    private func fetchIPPTransactions() {
        do {
            try resultsController.performFetch()
        } catch {
            DDLogError("Error fetching IPP transactions: \(error)")
        }
    }
}

private extension InPersonPaymentsMenuViewModel {
    /// Results controller that fetches IPP transactions
    ///
    func createIPPOrdersResultsController() -> ResultsController<StorageOrder> {
        let today = Date()
        let thirtyDaysBeforeToday = Calendar.current.date(
            byAdding: .day,
            value: -30,
            to: today
        )!

        let predicate = NSPredicate(
            format: "siteID == %lld AND paymentMethodID == %@ AND datePaid >= %@",
            argumentArray: [siteID ?? 0, "woocommerce_payments", thirtyDaysBeforeToday]
        )

        return ResultsController<StorageOrder>(storageManager: storage, matching: predicate, sortedBy: [])
    }
}

private enum Constants {
    static let utmCampaign = "payments_menu_item"
    static let utmSource = "payments_menu"
}
