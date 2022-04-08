import Foundation
import Combine
import Yosemite
import protocol Storage.StorageManagerType

/// Protocol to abstract the `CollectOrderPaymentUseCase`.
/// Currently only used to facilitate unit tests.
///
protocol RefundSubmissionProtocol {
    /// Starts the refund submission flow.
    ///
    /// - Parameter refund: the refund to submit.
    /// - Parameter showInProgressUI: called when the in-progress UI should be shown during refund submission.
    /// - Parameter onCompletion: called when the refund completes.
    func submitRefund(_ refund: Refund,
                      showInProgressUI: @escaping (() -> Void),
                      onCompletion: @escaping (Result<Void, Error>) -> Void)
}

/// Use case to submit a refund for an order.
/// If in-person refund is required for the payment method (e.g. Interac in Canada), orchestrates reader connection, refund, UI alerts,
/// submit refund to the site, and analytics.
/// Otherwise, it submits the refund to the site directly with analytics.
final class RefundSubmissionUseCase: NSObject, RefundSubmissionProtocol {
    /// Store's ID.
    private let siteID: Int64

    /// Refund details.
    private let details: Details

    /// Order of the refund.
    private var order: Order {
        details.order
    }

    /// Currency formatted needed for decimal calculations.
    private let currencyFormatter: CurrencyFormatter

    /// Formatted amount to collect.
    private let formattedAmount: String

    /// Stores manager.
    private let stores: StoresManager

    /// Storage manager for fetching payment gateway accounts.
    private let storageManager: StorageManagerType

    /// Analytics manager.
    private let analytics: Analytics

    /// View controller used to present alerts.
    private var rootViewController: UIViewController

    /// Stores the card reader listener subscription while trying to connect to one.
    private var readerSubscription: AnyCancellable?

    /// Stores the connected card reader for analytics.
    private var connectedReader: CardReader?

    /// Alert manager to inform merchants about reader & card actions.
    private var alerts: OrderDetailsPaymentAlerts?

    /// In-person refund orchestrator.
    private lazy var cardPresentRefundOrchestrator = CardPresentRefundOrchestrator(stores: stores)

    /// Controller to connect a card reader for in-person refund.
    private lazy var cardReaderConnectionController = CardReaderConnectionController(forSiteID: siteID,
                                                                                     knownReaderProvider: CardReaderSettingsKnownReaderStorage(),
                                                                                     alertsProvider: CardReaderSettingsAlerts(),
                                                                                     configuration: cardPresentConfigurationLoader.configuration)

    /// IPP Configuration loader.
    private lazy var cardPresentConfigurationLoader = CardPresentConfigurationLoader(stores: stores)

    /// PaymentGatewayAccount Results Controller.
    private lazy var paymentGatewayAccountResultsController: ResultsController<StoragePaymentGatewayAccount> = {
        let predicate = NSPredicate(format: "siteID = %ld", siteID)
        return ResultsController<StoragePaymentGatewayAccount>(storageManager: storageManager, matching: predicate, sortedBy: [])
    }()

    /// Payment Gateway Accounts for the site (i.e. that can be used to refund)
    private var paymentGatewayAccounts: [PaymentGatewayAccount] {
        paymentGatewayAccountResultsController.fetchedObjects
    }

    init(siteID: Int64,
         details: Details,
         rootViewController: UIViewController,
         currencyFormatter: CurrencyFormatter,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings,
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         analytics: Analytics = ServiceLocator.analytics) {
        self.siteID = siteID
        self.details = details
        self.formattedAmount = {
            let currencyCode = currencySettings.currencyCode
            let unit = currencySettings.symbol(from: currencyCode)
            return currencyFormatter.formatAmount(details.amount, with: unit) ?? ""
        }()
        self.rootViewController = rootViewController
        self.currencyFormatter = currencyFormatter
        self.stores = stores
        self.storageManager = storageManager
        self.analytics = analytics
    }

    /// Starts the refund submission flow.
    ///
    /// If in-person refund is required:
    /// 1. Connect to a reader
    /// 2. Refund with a card reader
    ///   - If successful: submit the refund to the site
    ///   - If failure: allow the customer to retry
    ///
    /// Otherwise, if in-person refund is not required, the refund is submitted directly to the site.
    ///
    /// - Parameters:
    ///   - refund: the refund to submit.
    ///   - showInProgressUI: called when the in-progress UI should be shown during refund submission.
    ///   - onCompletion: called when the refund completes.
    func submitRefund(_ refund: Refund,
                      showInProgressUI: @escaping (() -> Void),
                      onCompletion: @escaping (Result<Void, Error>) -> Void) {
        if let charge = details.charge, shouldRefundWithCardReader(details: details) {
            guard let refundAmount = currencyFormatter.convertToDecimal(from: details.amount) else {
                DDLogError("Error: attempted to refund an order without a valid amount.")
                onCompletion(.failure(RefundSubmissionError.invalidRefundAmount))
                return
            }
            observeConnectedReadersForAnalytics()
            connectReader { [weak self] in
                self?.attemptCardPresentRefund(refundAmount: refundAmount as Decimal, charge: charge, onCompletion: { [weak self] result in
                    guard let self = self else { return }
                    self.submitRefundToSite(refund: refund) { result in
                        onCompletion(result)
                    }
                })
            }
        } else {
            showInProgressUI()
            submitRefundToSite(refund: refund, onCompletion: onCompletion)
        }
    }
}

// MARK: Refund Details
extension RefundSubmissionUseCase {
    /// Details about a refund for submission.
    struct Details {
        /// Order to refund.
        let order: Order

        /// Charge of original payment.
        let charge: WCPayCharge?

        /// Total amount to refund.
        let amount: String
    }
}

// MARK: Private functions
private extension RefundSubmissionUseCase {
    /// Determines if in-person refund is required. Currently, only Interac payment method requires in-person refunds.
    /// - Parameter details: details about the refund.
    /// - Returns: whether the refund should be in-person with a card reader.
    func shouldRefundWithCardReader(details: Details) -> Bool {
        let isInterac: Bool = {
            switch details.charge?.paymentMethodDetails {
            case .some(.interacPresent):
                return true
            default:
                return false
            }
        }()
        return isInterac
    }

    /// Attempts to connect to a reader.
    /// Finishes immediately if a reader is already connected.
    func connectReader(onCompletion: @escaping () -> ()) {
        // `checkCardReaderConnected` action will return a publisher that:
        // - Sends one value if there is no reader connected.
        // - Completes when a reader is connected.
        let readerConnected = CardPresentPaymentAction.checkCardReaderConnected { [weak self] connectPublisher in
            guard let self = self else { return }
            self.readerSubscription = connectPublisher
                .sink(receiveCompletion: { [weak self] _ in
                    // Dismisses the current connection alert before notifying the completion.
                    // If no presented controller is found(because the reader was already connected), just notify the completion.
                    if let connectionController = self?.rootViewController.presentedViewController {
                        connectionController.dismiss(animated: true) {
                            onCompletion()
                        }
                    } else {
                        onCompletion()
                    }

                    // Nil the subscription since we are done with the connection.
                    self?.readerSubscription = nil

                }, receiveValue: { [weak self] _ in
                    guard let self = self else { return }

                    // Attempts reader connection
                    self.cardReaderConnectionController.searchAndConnect(from: self.rootViewController) { _ in }
                })
        }
        stores.dispatch(readerConnected)
    }

    /// Attempts to refund with a card reader when it is connected.
    ///
    /// - Parameters:
    ///   - refundAmount: the amount to refund.
    ///   - charge: the charge of the order for the refund to match the payment method.
    ///   - onCompletion: called when the in-person refund completes.
    func attemptCardPresentRefund(refundAmount: Decimal, charge: WCPayCharge, onCompletion: @escaping (Result<Void, Error>) -> ()) {
        // Fetches payment gateway accounts, at least one is required for in-person refunds.
        try? paymentGatewayAccountResultsController.performFetch()
        guard let paymentGatewayAccount = paymentGatewayAccounts.first else {
            onCompletion(.failure(RefundSubmissionError.unknownPaymentGatewayAccount))
            return
        }

        // Instantiates the alerts coordinator.
        let alerts = OrderDetailsPaymentAlerts(presentingController: rootViewController,
                                               paymentGatewayAccountID: paymentGatewayAccount.gatewayID,
                                               countryCode: cardPresentConfigurationLoader.configuration.countryCode,
                                               cardReaderModel: connectedReader?.readerType.model ?? "")
        self.alerts = alerts

        // Shows reader ready alert.
        alerts.readerIsReady(title: Localization.collectPaymentTitle(username: order.billingAddress?.firstName), amount: formattedAmount)

        // Starts refund process.
        cardPresentRefundOrchestrator.refund(amount: refundAmount,
                                             charge: charge,
                                             paymentGatewayAccount: paymentGatewayAccount,
                                             onWaitingForInput: { [weak self] in
            // Requests card input.
            self?.alerts?.tapOrInsertCard(onCancel: {
                self?.cancelRefund()
            })
        }, onProcessingMessage: { [weak self] in
            // Shows waiting message.
            self?.alerts?.processingPayment()
        }, onDisplayMessage: { [weak self] message in
            // Shows reader messages (e.g. Remove Card).
            self?.alerts?.displayReaderMessage(message: message)
        }, onCompletion: { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                onCompletion(.success(()))
            case .failure(let error):
                self.handleRefundFailureAndRetryRefund(error, refundAmount: refundAmount, charge: charge, onCompletion: onCompletion)
            }
        })
    }

    /// Logs the failure reason, cancels the current refund, and offers retry if possible.
    func handleRefundFailureAndRetryRefund(_ error: Error, refundAmount: Decimal, charge: WCPayCharge, onCompletion: @escaping (Result<Void, Error>) -> ()) {
        // TODO: 5984 - tracks in-person refund error
        DDLogError("Failed to refund: \(error.localizedDescription)")
        // Informs about the error.
        alerts?.error(error: error) { [weak self] in
            // Cancels current payment.
            self?.cardPresentRefundOrchestrator.cancelRefund { [weak self] result in
                guard let self = self else { return }

                switch result {
                case .success:
                    // Retries refund.
                    self.attemptCardPresentRefund(refundAmount: refundAmount, charge: charge, onCompletion: onCompletion)
                case .failure(let cancelError):
                    // Informs that payment can't be retried.
                    self.alerts?.nonRetryableError(from: self.rootViewController, error: cancelError)
                    onCompletion(.failure(error))
                }
            }
        }
    }

    /// Cancels refund and records analytics.
    func cancelRefund() {
        cardPresentRefundOrchestrator.cancelRefund { _ in
            // TODO: 5984 - tracks in-person refund cancellation
        }
    }

    /// Submits the refund to the site.
    /// - Parameters:
    ///   - refund: the refund to submit.
    ///   - onCompletion: called when the submission completes.
    func submitRefundToSite(refund: Refund, onCompletion: @escaping (Result<Void, Error>) -> Void) {
        let action = RefundAction.createRefund(siteID: details.order.siteID, orderID: details.order.orderID, refund: refund) { [weak self] _, error  in
            guard let self = self else { return }
            if let error = error {
                DDLogError("Error creating refund: \(refund)\nWith Error: \(error)")
                self.trackCreateRefundRequestFailed(error: error)
                return onCompletion(.failure(error))
            }
            onCompletion(.success(()))
            self.trackCreateRefundRequestSuccess()
        }
        stores.dispatch(action)
        trackCreateRefundRequest()
    }
}

// MARK: - Analytics
private extension RefundSubmissionUseCase {
    /// Tracks when the create refund request is made.
    func trackCreateRefundRequest() {
        analytics.track(event: WooAnalyticsEvent.IssueRefund.createRefund(orderID: details.order.orderID,
                                                                          fullyRefunded: details.amount == details.order.total,
                                                                          method: .items,
                                                                          gateway: details.order.paymentMethodID,
                                                                          amount: details.amount))
    }

    /// Tracks when the create refund request succeeds.
    func trackCreateRefundRequestSuccess() {
        analytics.track(event: WooAnalyticsEvent.IssueRefund.createRefundSuccess(orderID: details.order.orderID))
    }

    /// Tracks when the create refund request fails.
    func trackCreateRefundRequestFailed(error: Error) {
        analytics.track(event: WooAnalyticsEvent.IssueRefund.createRefundFailed(orderID: details.order.orderID, error: error))
    }
}

// MARK: Connected Card Readers
private extension RefundSubmissionUseCase {
    func observeConnectedReadersForAnalytics() {
        let action = CardPresentPaymentAction.observeConnectedReaders() { [weak self] readers in
            self?.connectedReader = readers.first
        }
        stores.dispatch(action)
    }
}

// MARK: Definitions
private extension RefundSubmissionUseCase {
    /// Mailing a receipt failed but the SDK didn't return a more specific error
    ///
    enum RefundSubmissionError: Error {
        case invalidRefundAmount
        case unknownPaymentGatewayAccount
    }

    enum Localization {
        private static let collectPaymentWithoutName = NSLocalizedString("Refund payment",
                                                                         comment: "Alert title when starting the in-person refund flow without a user name.")
        private static let collectPaymentWithName = NSLocalizedString("Refund payment from %1$@",
                                                                      comment: "Alert title when starting the in-person refund flow with a user name.")
        static func collectPaymentTitle(username: String?) -> String {
            guard let username = username, username.isNotEmpty else {
                return collectPaymentWithoutName
            }
            return .localizedStringWithFormat(collectPaymentWithName, username)
        }
    }
}
