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

    private var isCODEnabled: Bool {
        guard let siteID = siteID,
              let codGateway = dependencies.storage.viewStorage.loadPaymentGateway(siteID: siteID, gatewayID: "cod")?.toReadOnly() else {
            return false
        }
        return codGateway.enabled
    }

    private lazy var resultsController = createRecentIPPOrdersResultsController()

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

    /// This method is just a helper for debugging, we may use it for populating different Banner content based on the fetched objects count
    ///
    func displayIPPFeedbackBannerIfEligible() {
        if isCODEnabled {
            // Debug:
            let results = resultsController.fetchedObjects
            let resultsCount = results.count
            print("IPP transactions within 30 days: \(resultsCount)")
            print(results.map { ("OrderID: \($0.orderID) - PaymentMethodID: \($0.paymentMethodID) - DatePaid: \(String(describing: $0.datePaid))") })

            if resultsCount == 0 {
                // TODO: Should this option use a different results controller? We're looking for 0 orders historically, not within 30 days.
                print("0 transactions. Banner 1 shown")
            }
            else if resultsCount < 10 {
                print("< 10 transactions within 30 days. Banner 2 shown")
            } else if resultsCount >= 10 {
                print(">= 10 transactions within 30 days. Banner 3 shown")
            }
        } else {
            print("COD not enabled.")
            DDLogInfo("COD not enabled.")
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
    /// Results controller that fetches IPP transactions within the last 30 days
    ///
    func createRecentIPPOrdersResultsController() -> ResultsController<StorageOrder> {
        let today = Date()
        let paymentGateway = Constants.wcpay
        let thirtyDaysBeforeToday = Calendar.current.date(
            byAdding: .day,
            value: -30,
            to: today
        )!

        // TODO: Question. Are we looking for the paymentMethodID to be woocommerce_payments? Or COD?
        let predicate = NSPredicate(
            format: "siteID == %lld AND paymentMethodID == %@ AND datePaid >= %@",
            argumentArray: [siteID ?? 0, paymentGateway, thirtyDaysBeforeToday]
        )

        return ResultsController<StorageOrder>(storageManager: storage, matching: predicate, sortedBy: [])
    }
}

private enum Constants {
    static let utmCampaign = "payments_menu_item"
    static let utmSource = "payments_menu"
    static let wcpay = "woocommerce_payments"
}
