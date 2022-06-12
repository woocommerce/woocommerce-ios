import Foundation
import Combine
import Yosemite
import WooFoundation
import protocol Storage.StorageManagerType

/// Protocol to abstract the `RefundSubmissionUseCase`.
/// TODO: 5983 - Use this to facilitate unit tests.
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
    private let alerts: OrderDetailsPaymentAlertsProtocol

    /// In-person refund orchestrator.
    private lazy var cardPresentRefundOrchestrator = CardPresentRefundOrchestrator(stores: stores)

    /// Alert manager to inform merchants about card reader connection actions used in `CardReaderConnectionController`.
    private let cardReaderConnectionAlerts: CardReaderSettingsAlertsProvider

    /// Provides any known card reader to be used in `CardReaderConnectionController`.
    private let knownReaderProvider: CardReaderSettingsKnownReaderProvider

    /// Presents the card present onboarding flow, when required.
    /// It is shown before processing a refund which is processed via the card reader.
    private let cardPresentPaymentsOnboardingPresenter: CardPresentPaymentsOnboardingPresenting

    /// Controller to connect a card reader for in-person refund.
    private lazy var cardReaderConnectionController =
    CardReaderConnectionController(forSiteID: order.siteID,
                                   storageManager: storageManager,
                                   stores: stores,
                                   knownReaderProvider: knownReaderProvider,
                                   alertsProvider: cardReaderConnectionAlerts,
                                   configuration: cardPresentConfiguration,
                                   analyticsTracker: .init(configuration: cardPresentConfiguration,
                                                           stores: stores,
                                                           analytics: analytics))

    /// IPP Configuration.
    private let cardPresentConfiguration: CardPresentPaymentsConfiguration

    struct Dependencies {
        let cardReaderConnectionAlerts: CardReaderSettingsAlertsProvider
        let currencyFormatter: CurrencyFormatter
        let currencySettings: CurrencySettings
        let knownReaderProvider: CardReaderSettingsKnownReaderProvider
        let cardPresentPaymentsOnboardingPresenter: CardPresentPaymentsOnboardingPresenting
        let stores: StoresManager
        let storageManager: StorageManagerType
        let analytics: Analytics

        init(cardReaderConnectionAlerts: CardReaderSettingsAlertsProvider = CardReaderSettingsAlerts(),
             currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
             currencySettings: CurrencySettings = ServiceLocator.currencySettings,
             knownReaderProvider: CardReaderSettingsKnownReaderProvider = CardReaderSettingsKnownReaderStorage(),
             cardPresentPaymentsOnboardingPresenter: CardPresentPaymentsOnboardingPresenting = CardPresentPaymentsOnboardingPresenter(),
             stores: StoresManager = ServiceLocator.stores,
             storageManager: StorageManagerType = ServiceLocator.storageManager,
             analytics: Analytics = ServiceLocator.analytics) {
            self.cardReaderConnectionAlerts = cardReaderConnectionAlerts
            self.currencyFormatter = currencyFormatter
            self.currencySettings = currencySettings
            self.knownReaderProvider = knownReaderProvider
            self.cardPresentPaymentsOnboardingPresenter = cardPresentPaymentsOnboardingPresenter
            self.stores = stores
            self.storageManager = storageManager
            self.analytics = analytics
        }
    }

    init(details: Details,
         rootViewController: UIViewController,
         alerts: OrderDetailsPaymentAlertsProtocol,
         cardPresentConfiguration: CardPresentPaymentsConfiguration,
         dependencies: Dependencies = Dependencies()) {
        self.details = details
        self.formattedAmount = {
            let currencyCode = dependencies.currencySettings.currencyCode
            let unit = dependencies.currencySettings.symbol(from: currencyCode)
            return dependencies.currencyFormatter.formatAmount(details.amount, with: unit) ?? ""
        }()
        self.rootViewController = rootViewController
        self.alerts = alerts
        self.cardReaderConnectionAlerts = dependencies.cardReaderConnectionAlerts
        self.currencyFormatter = dependencies.currencyFormatter
        self.cardPresentConfiguration = cardPresentConfiguration
        self.knownReaderProvider = dependencies.knownReaderProvider
        self.cardPresentPaymentsOnboardingPresenter = dependencies.cardPresentPaymentsOnboardingPresenter
        self.stores = dependencies.stores
        self.storageManager = dependencies.storageManager
        self.analytics = dependencies.analytics
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
            cardPresentPaymentsOnboardingPresenter.showOnboardingIfRequired(
                from: rootViewController) { [weak self] in
                guard let self = self else { return }
                guard let refundAmount = self.currencyFormatter.convertToDecimal(self.details.amount) else {
                    DDLogError("Error: attempted to refund an order without a valid amount.")
                    return onCompletion(.failure(RefundSubmissionError.invalidRefundAmount))
                }

                guard let paymentGatewayAccount = self.details.paymentGatewayAccount else {
                    return onCompletion(.failure(RefundSubmissionError.unknownPaymentGatewayAccount))
                }

                self.observeConnectedReadersForAnalytics()
                self.connectReader(charge: charge, paymentGatewayAccount: paymentGatewayAccount) { [weak self] result in
                    guard let self = self else { return }
                    switch result {
                    case .success:
                        self.attemptCardPresentRefund(refundAmount: refundAmount as Decimal,
                                                      charge: charge,
                                                      paymentGatewayAccount: paymentGatewayAccount) { [weak self] result in
                            guard let self = self else { return }
                            switch result {
                            case .success:
                                self.submitRefundToSite(refund: refund) { result in
                                    onCompletion(result)
                                }
                            case .failure(let error):
                                onCompletion(.failure(error))
                            }
                        }
                    case .failure:
                        onCompletion(result)
                    }
                }
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

        /// Payment Gateway Account for the site (i.e. that can be used to refund).
        let paymentGatewayAccount: PaymentGatewayAccount?
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
    /// Finishes with success immediately if a reader is already connected.
    func connectReader(charge: WCPayCharge, paymentGatewayAccount: PaymentGatewayAccount, onCompletion: @escaping (Result<Void, Error>) -> ()) {
        // `checkCardReaderConnected` action will return a publisher that:
        // - Sends one value if there is no reader connected.
        // - Completes when a reader is connected.
        let readerConnected = CardPresentPaymentAction.publishCardReaderConnections { [weak self] connectPublisher in
            guard let self = self else { return }
            self.readerSubscription = connectPublisher
                .sink() { [weak self] readers in
                    guard let self = self else { return }

                    if readers.isNotEmpty {
                        // Dismisses the current connection alert before notifying the completion.
                        // If no presented controller is found(because the reader was already connected), just notify the completion.
                        if let connectionController = self.rootViewController.presentedViewController {
                            connectionController.dismiss(animated: true) {
                                onCompletion(.success(()))
                            }
                        } else {
                            onCompletion(.success(()))
                        }

                        // Nil the subscription since we are done with the connection.
                        self.readerSubscription = nil
                    } else {
                        // Attempts reader connection
                        self.cardReaderConnectionController.searchAndConnect(from: self.rootViewController) { [weak self] result in
                            guard let self = self else { return }
                            switch result {
                            case let .success(connectionResult):
                                switch connectionResult {
                                case .canceled:
                                    self.readerSubscription = nil
                                    self.trackClientSideRefundCanceled(charge: charge, paymentGatewayAccount: paymentGatewayAccount)
                                    onCompletion(.failure(RefundSubmissionError.cardReaderDisconnected))
                                case .connected:
                                    // Connected case will be handled in `if readers.isNotEmpty`.
                                    break
                                }
                            case .failure(let error):
                                self.readerSubscription = nil
                                onCompletion(.failure(error))
                            }
                        }
                    }
                }
        }
        stores.dispatch(readerConnected)
    }

    /// Attempts to refund with a card reader when it is connected.
    ///
    /// - Parameters:
    ///   - refundAmount: the amount to refund.
    ///   - charge: the charge of the order for the refund to match the payment method.
    ///   - paymentGatewayAccount: the payment gateway account for the site to refund (e.g. WCPay or Stripe extension).
    ///   - onCompletion: called when the in-person refund completes.
    private func attemptCardPresentRefund(refundAmount: Decimal,
                                  charge: WCPayCharge,
                                  paymentGatewayAccount: PaymentGatewayAccount,
                                  onCompletion: @escaping (Result<Void, Error>) -> ()) {
        // Shows reader ready alert.
        alerts.readerIsReady(title: Localization.refundPaymentTitle(username: order.billingAddress?.firstName),
                             amount: formattedAmount,
                             onCancel: { [weak self] in
            self?.cancelRefund(charge: charge, paymentGatewayAccount: paymentGatewayAccount, onCompletion: onCompletion)
        })

        // Starts refund process.
        cardPresentRefundOrchestrator.refund(amount: refundAmount,
                                             charge: charge,
                                             paymentGatewayAccount: paymentGatewayAccount,
                                             onWaitingForInput: { [weak self] in
            // Requests card input.
            self?.alerts.tapOrInsertCard(onCancel: { [weak self] in
                self?.cancelRefund(charge: charge, paymentGatewayAccount: paymentGatewayAccount, onCompletion: onCompletion)
            })
        }, onProcessingMessage: { [weak self] in
            // Shows waiting message.
            self?.alerts.processingPayment()
        }, onDisplayMessage: { [weak self] message in
            // Shows reader messages (e.g. Remove Card).
            self?.alerts.displayReaderMessage(message: message)
        }, onCompletion: { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                self.trackClientSideRefundRequestSuccess(charge: charge, paymentGatewayAccount: paymentGatewayAccount)
                onCompletion(.success(()))
            case .failure(let error):
                self.trackClientSideRefundRequestFailed(charge: charge, paymentGatewayAccount: paymentGatewayAccount, error: error)
                self.handleRefundFailureAndRetryRefund(error,
                                                       refundAmount: refundAmount,
                                                       charge: charge,
                                                       paymentGatewayAccount: paymentGatewayAccount,
                                                       onCompletion: onCompletion)
            }
        })
    }

    /// Logs the failure reason, cancels the current refund, and offers retry if possible.
    private func handleRefundFailureAndRetryRefund(_ error: Error,
                                           refundAmount: Decimal,
                                           charge: WCPayCharge,
                                           paymentGatewayAccount: PaymentGatewayAccount,
                                           onCompletion: @escaping (Result<Void, Error>) -> ()) {
        // TODO: 5984 - tracks in-person refund error
        DDLogError("Failed to refund: \(error.localizedDescription)")
        // Informs about the error.
        if let cardReaderError = error as? CardReaderServiceError,
           case .refundPayment(_, let shouldRetry) = cardReaderError,
           shouldRetry == false {
            alerts.nonRetryableError(from: rootViewController, error: error) {
                onCompletion(.failure(error))
            }
        } else {
            alerts.error(error: error, tryAgain: { [weak self] in
                // Cancels current refund, if possible.
                self?.cardPresentRefundOrchestrator.cancelRefund { [weak self] _ in
                    // Regardless of whether the refund could be cancelled (e.g. it completed but failed), retry the refund.
                    self?.attemptCardPresentRefund(refundAmount: refundAmount,
                                                                 charge: charge,
                                                                 paymentGatewayAccount: paymentGatewayAccount,
                                                                 onCompletion: onCompletion)
                }
            }, dismissCompletion: {
                onCompletion(.failure(error))
            })
        }
    }

    /// Cancels refund and records analytics.
    func cancelRefund(charge: WCPayCharge, paymentGatewayAccount: PaymentGatewayAccount, onCompletion: @escaping (Result<Void, Error>) -> ()) {
        trackClientSideRefundCanceled(charge: charge, paymentGatewayAccount: paymentGatewayAccount)
        cardPresentRefundOrchestrator.cancelRefund { _ in
            onCompletion(.failure(RefundSubmissionError.canceledByUser))
        }
    }

    /// Submits the refund to the site.
    /// - Parameters:
    ///   - refund: the refund to submit.
    ///   - onCompletion: called when the submission completes.
    func submitRefundToSite(refund: Refund, onCompletion: @escaping (Result<Void, Error>) -> Void) {

        let action = RefundAction.createRefund(siteID: details.order.siteID, orderID: details.order.orderID, refund: refund) { [weak self]
            refundData, error  in

            guard let self = self else { return }

            if let refundData = refundData {
                // Workaround for https://github.com/woocommerce/woocommerce/issues/33389. This can be removed when the related API issue is fixed
                self.retrieveUpdatedRefundData(refund: refundData)
            }
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

    /// Retrieves the up-to-date refund data
    /// - Parameters:
    ///   - refund: the refund to retrieve details from.
    private func retrieveUpdatedRefundData(refund: Refund) {
        let action = RefundAction.retrieveRefund(siteID: details.order.siteID, orderID: details.order.orderID, refundID: refund.refundID) { (_, error) in
                if let error = error {
                    DDLogError("Error retrieving refund: \(String(describing: refund))\nWith Error: \(error)")
                }
            }
            stores.dispatch(action)
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

    /// Tracks when the refund request succeeds on the client-side before submitting to the site.
    func trackClientSideRefundRequestSuccess(charge: WCPayCharge, paymentGatewayAccount: PaymentGatewayAccount) {
        switch charge.paymentMethodDetails {
        case .interacPresent:
            analytics.track(event: WooAnalyticsEvent.InPersonPayments
                .interacRefundSuccess(gatewayID: paymentGatewayAccount.gatewayID,
                                      countryCode: cardPresentConfiguration.countryCode,
                                      cardReaderModel: connectedReader?.readerType.model ?? ""))
        default:
            // Tracks refund success events with other payment methods if needed.
            return
        }
    }

    /// Tracks when the refund request fails on the client-side before submitting to the site.
    func trackClientSideRefundRequestFailed(charge: WCPayCharge, paymentGatewayAccount: PaymentGatewayAccount, error: Error) {
        switch charge.paymentMethodDetails {
        case .interacPresent:
            analytics.track(event: WooAnalyticsEvent.InPersonPayments
                .interacRefundFailed(error: error,
                                     gatewayID: paymentGatewayAccount.gatewayID,
                                     countryCode: cardPresentConfiguration.countryCode,
                                     cardReaderModel: connectedReader?.readerType.model ?? ""))
        default:
            // Tracks refund failure events with other payment methods if needed.
            return
        }
    }

    /// Tracks when the refund request is canceled on the client-side.
    func trackClientSideRefundCanceled(charge: WCPayCharge, paymentGatewayAccount: PaymentGatewayAccount) {
        switch charge.paymentMethodDetails {
        case .interacPresent:
            analytics.track(event: .InPersonPayments.interacRefundCanceled(gatewayID: paymentGatewayAccount.gatewayID,
                                                                           countryCode: cardPresentConfiguration.countryCode,
                                                                           cardReaderModel: connectedReader?.readerType.model ?? ""))
        default:
            // Tracks refund cancellation events with other payment methods if needed.
            return
        }
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
extension RefundSubmissionUseCase {
    /// Mailing a receipt failed but the SDK didn't return a more specific error
    ///
    enum RefundSubmissionError: Error, Equatable {
        case cardReaderDisconnected
        case invalidRefundAmount
        case unknownPaymentGatewayAccount
        case canceledByUser
    }
}

private extension RefundSubmissionUseCase {
    enum Localization {
        private static let refundPaymentWithoutName = NSLocalizedString("Refund payment",
                                                                        comment: "Alert title when starting the in-person refund flow without a user name.")
        private static let refundPaymentWithName = NSLocalizedString("Refund payment from %1$@",
                                                                     comment: "Alert title when starting the in-person refund flow with a user name.")
        static func refundPaymentTitle(username: String?) -> String {
            guard let username = username, username.isNotEmpty else {
                return refundPaymentWithoutName
            }
            return .localizedStringWithFormat(refundPaymentWithName, username)
        }
    }
}
