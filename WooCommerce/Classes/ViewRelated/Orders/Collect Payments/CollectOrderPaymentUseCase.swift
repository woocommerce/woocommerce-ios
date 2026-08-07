import Foundation
import Combine
import Yosemite
import MessageUI
import WordPressUI
import WooFoundation
import UIKit
//TODO: Move to alertprovider (and ideally, remove from this target or translate through Yosemite)
import enum Hardware.CardReaderServiceError
import enum Hardware.UnderlyingError

/// Protocol to abstract the `CollectOrderPaymentUseCase`.
/// Currently only used to facilitate unit tests.
///
protocol CollectOrderPaymentProtocol {
    /// Starts the collect payment flow.
    ///
    /// - Parameter using: We specify a discovery method to allow us to choose between Tap to Pay and Bluetooth readers, which have distinct connection flows.
    /// - Parameter onCompleted: Closure Invoked after the flow has been totally completed.
    /// - Parameter onCancel: Closure invoked after the flow is cancelled
    /// - Parameter onFailure: Closure invoked when there is an error in the flow
    /// - Parameter onPaymentCompletion: Closure invoked after any payment completes, but while the user can still continue with the flow in some way
    func collectPayment(using: CardReaderDiscoveryMethod,
                        channel: PaymentChannel,
                        onFailure: @escaping (Error) -> Void,
                        onCancel: @escaping () -> Void,
                        onPaymentCompletion: @escaping () -> Void,
                        onCompleted: @escaping () -> Void)
}

/// Use case to collect payments from an order.
/// Orchestrates reader connection, payment, UI alerts, receipt handling and analytics.
///
final class CollectOrderPaymentUseCase<TapToPayAlertProvider: CardReaderTransactionAlertsProviding,
                                        BluetoothAlertProvider: CardReaderTransactionAlertsProviding,
                                        AlertPresenter: CardPresentPaymentAlertsPresenting>:
    NSObject, CollectOrderPaymentProtocol
where TapToPayAlertProvider.AlertDetails == AlertPresenter.AlertDetails,
      BluetoothAlertProvider.AlertDetails == AlertPresenter.AlertDetails {
    /// Currency Formatter
    ///
    private let currencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)

    /// Store's ID.
    ///
    private let siteID: Int64

    /// Order to collect.
    ///
    private var order: Order

    /// Order total in decimal number. It is lazy so we avoid multiple conversions.
    /// It can be lazy because the order is a constant and never changes (this class is intended to be
    /// fired and disposed, not reused for multiple payment flows).
    ///
    private lazy var orderTotal: NSDecimalNumber? = {
        currencyFormatter.convertToDecimal(order.total)
    }()

    /// Formatted amount to collect.
    ///
    private let formattedAmount: String

    private let stores: StoresManager

    private let analyticsTracker: CollectOrderPaymentAnalyticsTracking

    /// View Controller used to present alerts.
    ///
    private let rootViewController: ViewControllerPresenting

    /// Alerts presenter: alerts from the various parts of the payment process are forwarded here
    ///
    private let alertsPresenter: any CardPresentPaymentAlertsPresenting<AlertPresenter.AlertDetails>

    private let bluetoothAlertsProvider: any CardReaderTransactionAlertsProviding<AlertPresenter.AlertDetails>

    private let tapToPayAlertsProvider: any CardReaderTransactionAlertsProviding<AlertPresenter.AlertDetails>

    /// Stores the card reader listener subscription while trying to connect to one.
    ///
    private var readerSubscription: AnyCancellable?

    private let configuration: CardPresentPaymentsConfiguration

    private let paymentOrchestrator: PaymentCaptureOrchestrating

    /// Coordinates emailing a receipt after payment success.
    private var receiptEmailCoordinator: CardPresentPaymentReceiptEmailCoordinator?

    private let preflightController: CardPresentPaymentPreflightControllerProtocol

    private let receiptEligibilityUseCase: ReceiptEligibilityUseCaseProtocol

    private var cancellables: Set<AnyCancellable> = []

    private let notificationCenter: NotificationCenter
    private let applicationStateProvider: () -> UIApplication.State
    private var applicationReactivationCancellable: AnyCancellable?

    private enum CancellationOutcomeState: Equatable {
        case pending
        case awaitingConfirmation
        case completed
    }

    private var cancellationOutcomeState: CancellationOutcomeState = .pending

    /// Serializes cancellation with payment startup so cancellation cannot land between the final state check and
    /// registration of the Hardware payment attempt.
    private let paymentFlowLock = NSRecursiveLock()
    private var paymentFlowCanceled = false

    private var isPaymentFlowCanceled: Bool {
        paymentFlowLock.lock()
        defer { paymentFlowLock.unlock() }
        return paymentFlowCanceled
    }

    init(siteID: Int64,
         order: Order,
         formattedAmount: String,
         rootViewController: ViewControllerPresenting,
         configuration: CardPresentPaymentsConfiguration,
         stores: StoresManager = ServiceLocator.stores,
         paymentOrchestrator: PaymentCaptureOrchestrating = PaymentCaptureOrchestrator(),
         orderDurationRecorder: OrderDurationRecorderProtocol = OrderDurationRecorder.shared,
         alertsPresenter: any CardPresentPaymentAlertsPresenting<AlertPresenter.AlertDetails>,
         tapToPayAlertsProvider: any CardReaderTransactionAlertsProviding<AlertPresenter.AlertDetails>,
         bluetoothAlertsProvider: any CardReaderTransactionAlertsProviding<AlertPresenter.AlertDetails>,
         preflightController: CardPresentPaymentPreflightControllerProtocol,
         analyticsTracker: CollectOrderPaymentAnalyticsTracking? = nil,
         receiptEligibilityUseCase: ReceiptEligibilityUseCaseProtocol = ReceiptEligibilityUseCase(),
         notificationCenter: NotificationCenter = .default,
         applicationStateProvider: @escaping () -> UIApplication.State = { UIApplication.shared.applicationState }) {
        self.siteID = siteID
        self.order = order
        self.formattedAmount = formattedAmount
        self.rootViewController = rootViewController
        self.alertsPresenter = alertsPresenter
        self.tapToPayAlertsProvider = tapToPayAlertsProvider
        self.bluetoothAlertsProvider = bluetoothAlertsProvider
        self.configuration = configuration
        self.stores = stores
        self.paymentOrchestrator = paymentOrchestrator
        self.preflightController = preflightController
        self.analyticsTracker = analyticsTracker ?? CollectOrderPaymentAnalytics(siteID: siteID,
                                                                                 analytics: ServiceLocator.analytics,
                                                                                 configuration: configuration,
                                                                                 orderDurationRecorder: orderDurationRecorder)
        self.receiptEligibilityUseCase = receiptEligibilityUseCase
        self.notificationCenter = notificationCenter
        self.applicationStateProvider = applicationStateProvider
    }

    /// Starts the collect payment flow.
    /// 1. Checks valid total
    /// 2. Calls CardReaderPreflightController to get a connected reader
    /// 3. Hands off to PaymentCaptureOrchestrator to perform the payment
    /// 4. Shows payment messages using an alert provider appropriate to the reader type
    /// 5. Handles receipt alerts on success
    /// 6. Allows retry on failure
    /// 7. Tracks payment analytics
    ///
    ///
    /// - Parameter channel: The channel where the payment is being collected (e.g. POS, store management).
    /// - Parameter onFailure: Closure invoked after the payment process fails.
    /// - Parameter onCancel: Closure invoked after the flow is cancelled
    /// - Parameter onCompleted: Closure invoked after the flow has been totally completed, currently after merchant has handled the receipt.
    func collectPayment(using discoveryMethod: CardReaderDiscoveryMethod,
                        channel: PaymentChannel,
                        onFailure: @escaping (Error) -> Void,
                        onCancel: @escaping () -> Void,
                        onPaymentCompletion: @escaping () -> Void,
                        onCompleted: @escaping () -> Void) {
        setPaymentFlowCanceled(false)
        preflightController.readerConnection.sink { [weak self] connectionResult in
            guard let self else { return }
            self.analyticsTracker.preflightResultReceived(connectionResult)
            switch connectionResult {
            case .completed(let reader, let paymentGatewayAccount):
                let paymentAlertProvider = paymentAlertProvider(for: reader)
                self.attemptPayment(alertProvider: paymentAlertProvider,
                                    paymentGatewayAccount: paymentGatewayAccount,
                                    channel: channel,
                                    onCompletion: { [weak self] result in
                    guard let self else { return }
                    // Inform about the collect payment state
                    switch result {
                    case .failure(CollectOrderPaymentUseCaseError.flowCanceledByUser):
                        self.rootViewController.presentedViewController?.dismiss(animated: true)
                        return onCancel()
                    case .failure(let error):
                        CardPresentPaymentOnboardingStateCache.shared.invalidate()
                        return onFailure(error)
                    case .success(let paymentData):
                        self.storeInPersonPaymentsTransactionDateIfFirst(using: reader.readerType)
                        self.receiptEligibilityUseCase.isEligibleForBackendReceipts { [weak self] isEligible in
                            guard let self else { return }
                            if isEligible {
                                self.presentBackendReceiptAlert(alertProvider: paymentAlertProvider,
                                                                paymentMethod: paymentData.paymentMethod,
                                                                onCompleted: onCompleted)
                            } else {
                                onCompleted()
                            }
                            onPaymentCompletion()
                        }
                    }
                })
            case .canceled(let cancellationSource, _):
                self.handlePaymentCancellation(from: cancellationSource)
                onCancel()
            case .none:
                break
            }
        }
        .store(in: &cancellables)

        Task {
            await cancelReconnectionIfNeeded()
            await preflightController.start(discoveryMethod: discoveryMethod)
        }
    }

    private func paymentAlertProvider(for reader: CardReader) -> any CardReaderTransactionAlertsProviding<AlertPresenter.AlertDetails> {
        switch reader.readerType {
        case .tapToPay:
            return tapToPayAlertsProvider
        default:
            return bluetoothAlertsProvider
        }
    }
}

// MARK: Private functions
private extension CollectOrderPaymentUseCase {

    /// Cancels an automatic card reader reconnection since a new payment cannot begin while a reconnection is ongoing
    ///
    @MainActor
    func cancelReconnectionIfNeeded() async {
        await withCheckedContinuation { continuation in
            var nillableContinuation: CheckedContinuation<Void, Never>? = continuation
            let action = CardPresentPaymentAction.cancelReconnection { _ in
                nillableContinuation?.resume()
                nillableContinuation = nil
            }
            stores.dispatch(action)
        }
    }

    /// Checks whether the amount to be collected is valid: (not nil, convertible to decimal, higher than minimum amount ...)
    ///
    func isTotalAmountValid() -> Bool {
        guard let orderTotal else {
            return false
        }

        /// Bail out if the order amount is below the minimum allowed:
        /// https://stripe.com/docs/currencies#minimum-and-maximum-charge-amounts
        return orderTotal as Decimal >= configuration.minimumAllowedChargeAmount as Decimal
    }

    /// Determines and returns the error that provoked the amount being invalid
    ///
    func totalAmountInvalidError() -> Error {
        let orderTotalAmountCanBeConverted = orderTotal != nil

        guard orderTotalAmountCanBeConverted,
              let minimum = currencyFormatter.formatAmount(configuration.minimumAllowedChargeAmount, with: order.currency) else {
            return CollectOrderPaymentUseCaseNotValidAmountError.other
        }

        return CollectOrderPaymentUseCaseNotValidAmountError.belowMinimumAmount(amount: minimum)
    }

    func handleTotalAmountInvalidError(_ error: Error,
                                       alertProvider: any CardReaderTransactionAlertsProviding<AlertPresenter.AlertDetails>,
                                       onCompleted: @escaping () -> ()) {
        analyticsTracker.trackPaymentFailure(with: error)
        DDLogError("💳 Error: failed to capture payment for order. Order amount is below minimum or not valid")
        alertsPresenter.present(viewModel: alertProvider.nonRetryableError(error: totalAmountInvalidError(),
                                                                           receiptState: .noEmailReceipt,
                                                                           dismissCompletion: onCompleted))
    }

    func isOrderAwaitingPayment() -> Bool {
        order.datePaid == nil
    }

    func checkOrderIsStillEligibleForPayment(alertProvider paymentAlerts: any CardReaderTransactionAlertsProviding<AlertPresenter.AlertDetails>,
                                             onPaymentCompletion: @escaping (Result<CardPresentCapturedPaymentData, Error>) -> (),
                                             onCheckCompletion: @escaping (Result<Void, Error>) -> Void) {
        alertsPresenter.present(viewModel: paymentAlerts.validatingOrder(onCancel: { [weak self] in
            self?.cancelPayment(from: .paymentValidatingOrder, alertProvider: paymentAlerts) {
                onPaymentCompletion(.failure(CollectOrderPaymentUseCaseError.flowCanceledByUser))
            }
        }))

        let action = OrderAction.retrieveOrderRemotely(siteID: order.siteID, orderID: order.orderID) { [weak self] result in
            guard let self, isPaymentFlowCanceled == false else { return }

            switch result {
            case .success(let order):
                let orderTotal = currencyFormatter.convertToDecimal(order.total)
                let originalOrderTotal = currencyFormatter.convertToDecimal(self.order.total)
                guard orderTotal == originalOrderTotal else {
                    return onCheckCompletion(.failure(CollectOrderPaymentUseCaseError.orderTotalChanged))
                }

                self.order = order
            case .failure(let error):
                DDLogError("⛔️ Error synchronizing Order: \(error.localizedDescription)")
                return onCheckCompletion(.failure(CollectOrderPaymentUseCaseError.couldNotRefreshOrder(error)))
            }

            guard self.isTotalAmountValid() else {
                return onCheckCompletion(.failure(self.totalAmountInvalidError()))
            }

            guard self.isOrderAwaitingPayment() else {
                return onCheckCompletion(.failure(CollectOrderPaymentUseCaseError.orderAlreadyPaid))
            }

            onCheckCompletion(.success(()))
        }

        stores.dispatch(action)
    }

    /// Attempts to collect payment for an order.
    ///
    func attemptPayment(alertProvider paymentAlerts: any CardReaderTransactionAlertsProviding<AlertPresenter.AlertDetails>,
                        paymentGatewayAccount: PaymentGatewayAccount,
                        channel: PaymentChannel,
                        onCompletion: @escaping (Result<CardPresentCapturedPaymentData, Error>) -> ()) {
        checkOrderIsStillEligibleForPayment(alertProvider: paymentAlerts, onPaymentCompletion: onCompletion) { [weak self] result in
            guard let self, isPaymentFlowCanceled == false else { return }
            switch result {
            case .failure(let error):
                return self.checkThenHandlePaymentFailureAndRetryPayment(error,
                                                                         alertProvider: paymentAlerts,
                                                                         paymentGatewayAccount: paymentGatewayAccount,
                                                                         channel: channel,
                                                                         onCompletion: onCompletion)
            case .success:
                self.terminalPaymentPreparationEnabled(paymentGatewayAccount: paymentGatewayAccount) { [weak self] terminalPaymentPreparationEnabled in
                    guard let self, isPaymentFlowCanceled == false else { return }
                    self.collectPayment(alertProvider: paymentAlerts,
                                        paymentGatewayAccount: paymentGatewayAccount,
                                        terminalPaymentPreparationEnabled: terminalPaymentPreparationEnabled,
                                        channel: channel,
                                        onCompletion: onCompletion)
                }
            }
        }
    }

    func collectPayment(alertProvider paymentAlerts: any CardReaderTransactionAlertsProviding<AlertPresenter.AlertDetails>,
                        paymentGatewayAccount: PaymentGatewayAccount,
                        terminalPaymentPreparationEnabled: Bool,
                        channel: PaymentChannel,
                        onCompletion: @escaping (Result<CardPresentCapturedPaymentData, Error>) -> ()) {
        guard isPaymentFlowCanceled == false else { return }

        guard let orderTotal else {
            onCompletion(.failure(CollectOrderPaymentUseCaseNotValidAmountError.other))
            return
        }

        guard lockPaymentFlowForStart() else { return }
        defer { paymentFlowLock.unlock() }
        // Keep recovery state scoped to this payment attempt. POS may start another flow while
        // callbacks from an earlier flow are still unwinding.
        var paymentIntentForRecovery: PaymentIntent?
        let retrievePaymentIntentForRecovery = { paymentIntentForRecovery }

        // Start collect payment process
        paymentOrchestrator.collectPayment(
            for: order,
            orderTotal: orderTotal,
            paymentGatewayAccount: paymentGatewayAccount,
            paymentMethodTypes: configuration.paymentMethods,
            stripeSmallestCurrencyUnitMultiplier: configuration.stripeSmallestCurrencyUnitMultiplier,
            countryCode: configuration.countryCode,
            terminalPaymentPreparationEnabled: terminalPaymentPreparationEnabled,
            channel: channel,
            onPreparingReader: { [weak self] in
                guard let self, isPaymentFlowCanceled == false else { return }
                self.alertsPresenter.present(viewModel: paymentAlerts.preparingReader(onCancel: { [weak self] in
                    self?.cancelPayment(from: .paymentPreparingReader, alertProvider: paymentAlerts) {
                        onCompletion(.failure(CollectOrderPaymentUseCaseError.flowCanceledByUser))
                    }
                }))
            },
            onWaitingForInput: { [weak self] inputMethods in
                guard let self, isPaymentFlowCanceled == false else { return }
                self.alertsPresenter.present(
                    viewModel: paymentAlerts.tapOrInsertCard(
                        title: CollectOrderPaymentUseCaseDefinitions.Localization.collectPaymentTitle(
                            username: self.order.billingAddress?.firstName),
                        amount: self.formattedAmount,
                        inputMethods: inputMethods,
                        onCancel: { [weak self] in
                            self?.cancelPayment(from: .paymentWaitingForInput, alertProvider: paymentAlerts) {
                                onCompletion(.failure(CollectOrderPaymentUseCaseError.flowCanceledByUser))
                            }
                        })
                )
            }, onCardInserted: { [weak self] in
                guard let self, isPaymentFlowCanceled == false else { return }
                self.alertsPresenter.present(viewModel: paymentAlerts.cardInserted(
                    title: CollectOrderPaymentUseCaseDefinitions.Localization.collectPaymentTitle(
                        username: self.order.billingAddress?.firstName),
                    amount: self.formattedAmount,
                    onCancel: { [weak self] in
                        self?.cancelPayment(from: .paymentWaitingForInput, alertProvider: paymentAlerts) {
                            onCompletion(.failure(CollectOrderPaymentUseCaseError.flowCanceledByUser))
                        }
                    })
                )
            }, onProcessingMessage: { [weak self] in
                guard let self, isPaymentFlowCanceled == false else { return }
                // Waiting message
                self.alertsPresenter.present(
                    viewModel: paymentAlerts.processingTransaction(
                        title: CollectOrderPaymentUseCaseDefinitions.Localization.processingPaymentTitle(
                            username: self.order.billingAddress?.firstName)))
            }, onDisplayMessage: { [weak self] message in
                guard let self, isPaymentFlowCanceled == false else { return }
                // Reader messages. EG: Remove Card
                self.alertsPresenter.present(viewModel: paymentAlerts.displayReaderMessage(message: message))
            }, onProcessingCompletion: { [weak self] intent in
                paymentIntentForRecovery = intent
                self?.analyticsTracker.trackProcessingCompletion(intent: intent)
                self?.markOrderAsPaidIfNeeded(intent: intent)
            }, onCompletion: { [weak self] result in
                switch result {
                case .success(let capturedPaymentData):
                    self?.handleSuccessfulPayment(capturedPaymentData: capturedPaymentData)
                    onCompletion(.success(capturedPaymentData))
                case .failure(CardReaderServiceError.paymentMethodCollection(.commandCancelled(let cancellationSource))):
                    self?.handlePaymentMethodCollectionCancellation(cancellationSource, alertProvider: paymentAlerts)
                case .failure(let error):
                    self?.checkThenHandlePaymentFailureAndRetryPayment(error,
                                                                       alertProvider: paymentAlerts,
                                                                       paymentGatewayAccount: paymentGatewayAccount,
                                                                       channel: channel,
                                                                       paymentIntentForRecovery: retrievePaymentIntentForRecovery,
                                                                       onCompletion: onCompletion)
                }
            })
    }

    func terminalPaymentPreparationEnabled(paymentGatewayAccount: PaymentGatewayAccount,
                                           completion: @escaping (Bool) -> Void) {
        guard paymentGatewayAccount.gatewayID == WCPayAccount.gatewayID,
              terminalPaymentPreparationAvailableForConfiguration else {
            completion(false)
            return
        }

        terminalPaymentPreparationSupportedBySite(completion: completion)
    }

    var terminalPaymentPreparationAvailableForConfiguration: Bool {
        switch configuration.countryCode {
        case .AU, .CA:
            return true
        default:
            return false
        }
    }

    func terminalPaymentPreparationSupportedBySite(completion: @escaping (Bool) -> Void) {
        switch configuration.countryCode {
        case .AU:
            completion(true)
        case .CA:
            // Canada already supports in-person payments on older WCPay versions, so check for the
            // terminal preparation endpoint before using it. Once WCPay 10.8 has enough adoption in
            // Canada, consider raising the minimum WCPay version and removing this compatibility check.
            checkTerminalPaymentPreparationRoute(completion: completion)
        default:
            completion(false)
        }
    }

    func checkTerminalPaymentPreparationRoute(completion: @escaping (Bool) -> Void) {
        let action = SettingAction.retrieveSiteAPI(siteID: siteID) { result in
            switch result {
            case .success(let siteAPI):
                completion(siteAPI.hasTerminalPaymentPreparationRoute)
            case .failure(let error):
                DDLogInfo("💳 Skipping terminal payment preparation because the WCPay endpoint could not be verified: \(error)")
                completion(false)
            }
        }
        stores.dispatch(action)
    }

    /// Tracks the successful payments
    ///
    func handleSuccessfulPayment(capturedPaymentData: CardPresentCapturedPaymentData) {
        analyticsTracker.trackSuccessfulCardPayment(capturedPaymentData: capturedPaymentData)
    }

    func handlePaymentCancellation(from cancellationSource: WooAnalyticsEvent.InPersonPayments.CancellationSource) {
        analyticsTracker.trackPaymentCancelation(cancelationSource: cancellationSource)
        alertsPresenter.dismiss()
    }

    func handlePaymentMethodCollectionCancellation(
        _ cancellationSource: UnderlyingError.CancellationSource,
        alertProvider paymentAlerts: any CardReaderTransactionAlertsProviding<AlertPresenter.AlertDetails>
    ) {
        switch cancellationSource {
        case .reader:
            handlePaymentCancellationFromReader(alertProvider: paymentAlerts)
        case .app where isPaymentFlowCanceled:
            // The explicit cancellation request owns analytics and UI dismissal. Stripe's payment publisher also
            // completes with an app-cancelled error, but handling it here would dismiss the Woo UI too early.
            break
        case .app, .unknown:
            handlePaymentCancellation(from: .other)
        }
    }

    func handlePaymentCancellationFromReader(alertProvider paymentAlerts: any CardReaderTransactionAlertsProviding<AlertPresenter.AlertDetails>) {
        analyticsTracker.trackPaymentCancelation(cancelationSource: .reader)
        guard let dismissedOnReaderAlert = paymentAlerts.cancelledOnReader() else {
            return alertsPresenter.dismiss()
        }
        alertsPresenter.present(viewModel: dismissedOnReaderAlert)
    }

    /// Check whether payment was actually successful (for some errors which may hide success) – return success if it was.
    /// If it wasn't, log the failure reason, inform the user, and offer them the chance to retry it if possible.
    ///
    func checkThenHandlePaymentFailureAndRetryPayment(_ error: Error,
                                                      alertProvider paymentAlerts: any CardReaderTransactionAlertsProviding<AlertPresenter.AlertDetails>,
                                                      paymentGatewayAccount: PaymentGatewayAccount,
                                                      channel: PaymentChannel,
                                                      paymentIntentForRecovery: @escaping () -> PaymentIntent? = { nil },
                                                      onCompletion: @escaping (Result<CardPresentCapturedPaymentData, Error>) -> ()) {
        guard let paymentIntentForServerCapture = paymentIntentForRecovery(),
              let clientSecret = paymentIntentForServerCapture.clientSecret else {
            return handlePaymentFailureAndRetryPayment(error,
                                                       alertProvider: paymentAlerts,
                                                       paymentGatewayAccount: paymentGatewayAccount,
                                                       channel: channel,
                                                       paymentIntentForRecovery: paymentIntentForRecovery,
                                                       onCompletion: onCompletion)
        }

        // Once confirmation has completed, any later error may be ambiguous. Ask Stripe first so a
        // failed order refresh cannot hide a payment that was definitely taken.
        let retrieveIntentAction = CardPresentPaymentAction.retrievePaymentIntent(clientSecret: clientSecret) { [weak self] result in
            guard let self else { return }

            let refreshedIntent: PaymentIntent
            switch result {
            case .failure(let retrieveError):
                DDLogInfo("💳 Unable to verify terminal PaymentIntent after payment failure: \(retrieveError)")
                return handlePaymentFailureAndRetryPayment(error,
                                                           alertProvider: paymentAlerts,
                                                           paymentGatewayAccount: paymentGatewayAccount,
                                                           channel: channel,
                                                           paymentIntentForRecovery: paymentIntentForRecovery,
                                                           onCompletion: onCompletion)
            case .success(let intent):
                refreshedIntent = intent
            }

            guard refreshedIntent.id == paymentIntentForServerCapture.id else {
                DDLogInfo("💳 Unable to verify terminal payment: retrieved PaymentIntent does not match the captured intent")
                return handlePaymentFailureAndRetryPayment(error,
                                                           alertProvider: paymentAlerts,
                                                           paymentGatewayAccount: paymentGatewayAccount,
                                                           channel: channel,
                                                           paymentIntentForRecovery: paymentIntentForRecovery,
                                                           onCompletion: onCompletion)
            }

            guard refreshedIntent.metadata?[PaymentIntent.MetadataKeys.orderID] == String(order.orderID) else {
                DDLogInfo("💳 Unable to verify terminal payment: PaymentIntent order metadata does not match the order")
                return handlePaymentFailureAndRetryPayment(error,
                                                           alertProvider: paymentAlerts,
                                                           paymentGatewayAccount: paymentGatewayAccount,
                                                           channel: channel,
                                                           paymentIntentForRecovery: paymentIntentForRecovery,
                                                           onCompletion: onCompletion)
            }

            guard refreshedIntent.status == .succeeded else {
                DDLogInfo("💳 Unable to verify terminal payment: PaymentIntent status is \(refreshedIntent.status)")
                return handlePaymentFailureAndRetryPayment(error,
                                                           alertProvider: paymentAlerts,
                                                           paymentGatewayAccount: paymentGatewayAccount,
                                                           channel: channel,
                                                           paymentIntentForRecovery: paymentIntentForRecovery,
                                                           onCompletion: onCompletion)
            }

            let capturedPaymentData = CardPresentCapturedPaymentData(
                paymentMethod: refreshedIntent.paymentMethod() ?? .unknown,
                receiptParameters: refreshedIntent.receiptParameters()
            )
            handleSuccessfulPayment(capturedPaymentData: capturedPaymentData)
            onCompletion(.success(capturedPaymentData))
        }
        stores.dispatch(retrieveIntentAction)
    }

    /// Log the failure reason, inform the user, and offer them the chance to retry it if possible.
    ///
    func handlePaymentFailureAndRetryPayment(_ error: Error,
                                             alertProvider paymentAlerts: any CardReaderTransactionAlertsProviding<AlertPresenter.AlertDetails>,
                                             paymentGatewayAccount: PaymentGatewayAccount,
                                             channel: PaymentChannel,
                                             paymentIntentForRecovery: @escaping () -> PaymentIntent? = { nil },
                                             onCompletion: @escaping (Result<CardPresentCapturedPaymentData, Error>) -> ()) {
        DDLogError("Failed to collect payment: \(error.localizedDescription)")

        analyticsTracker.trackPaymentFailure(with: error)

        let presentErrorAlert: (CardReaderTransactionFailureAlertReceiptState) -> Void = { [weak self] receiptState in
            guard let self else { return }
            guard let retryableError = error as? CardPaymentErrorProtocol else {
                return presentNonRetryableError(error: error,
                                                paymentAlerts: paymentAlerts,
                                                receiptState: receiptState,
                                                onCompletion: onCompletion)
            }

            switch retryableError.retryApproach {
            case .restart:
                presentRetryByRestartingError(error: error,
                                              paymentAlerts: paymentAlerts,
                                              paymentGatewayAccount: paymentGatewayAccount,
                                              receiptState: receiptState,
                                              channel: channel,
                                              onCompletion: onCompletion)
            case .reuseIntent:
                presentRetryWithoutRestartingError(error: error,
                                                   paymentAlerts: paymentAlerts,
                                                   paymentGatewayAccount: paymentGatewayAccount,
                                                   receiptState: receiptState,
                                                   channel: channel,
                                                   paymentIntentForRecovery: paymentIntentForRecovery,
                                                   onCompletion: onCompletion)
            case .dontRetry:
                presentNonRetryableError(error: error,
                                         paymentAlerts: paymentAlerts,
                                         receiptState: receiptState,
                                         onCompletion: onCompletion)
            }
        }

        getReceiptStateForFailedPayment(error: error,
                                        paymentGatewayID: paymentGatewayAccount.gatewayID,
                                        completion: presentErrorAlert)
    }

    private func presentRetryByRestartingError(error: Error,
                                               paymentAlerts: any CardReaderTransactionAlertsProviding<AlertPresenter.AlertDetails>,
                                               paymentGatewayAccount: PaymentGatewayAccount,
                                               receiptState: CardReaderTransactionFailureAlertReceiptState,
                                               channel: PaymentChannel,
                                               onCompletion: @escaping (Result<CardPresentCapturedPaymentData, Error>) -> ()) {
        alertsPresenter.present(
            viewModel: paymentAlerts.error(error: error,
                                           receiptState: receiptState,
                                           tryAgain: { [weak self] in
                                               // Cancel current payment
                                               self?.paymentOrchestrator.cancelPayment() { [weak self] result in
                                                   guard let self else { return }

                                                   switch result {
                                                   case .success, .failure(CardReaderServiceError.paymentCancellation(.noActivePaymentIntent)):
                                                       // Retry payment
                                                       self.attemptPayment(alertProvider: paymentAlerts,
                                                                           paymentGatewayAccount: paymentGatewayAccount,
                                                                           channel: channel,
                                                                           onCompletion: onCompletion)
                                                   case .failure(let cancelError):
                                                       // Inform that payment can't be retried.
                                                       self.alertsPresenter.present(
                                                        viewModel: paymentAlerts.nonRetryableError(error: cancelError,
                                                                                                   receiptState: receiptState) {
                                                                                                       onCompletion(.failure(error))
                                                                                                   })
                                                   }
                                               }
                                           }, dismissCompletion: { [weak self] in
                                               guard let self else {
                                                   return onCompletion(.failure(error))
                                               }
                                               self.completeAfterErrorDismissal(error, onCompletion: onCompletion)
                                           })
        )
    }

    private func presentRetryWithoutRestartingError(error: Error,
                                                    paymentAlerts: any CardReaderTransactionAlertsProviding<AlertPresenter.AlertDetails>,
                                                    paymentGatewayAccount: PaymentGatewayAccount,
                                                    receiptState: CardReaderTransactionFailureAlertReceiptState,
                                                    channel: PaymentChannel,
                                                    paymentIntentForRecovery: @escaping () -> PaymentIntent?,
                                                    onCompletion: @escaping (Result<CardPresentCapturedPaymentData, Error>) -> ()) {
        alertsPresenter.present(
            viewModel: paymentAlerts.error(
                error: error,
                receiptState: receiptState,
                tryAgain: { [weak self] in
                    guard let self else { return }
                    self.checkOrderIsStillEligibleForPayment(alertProvider: paymentAlerts, onPaymentCompletion: onCompletion) { result in
                        switch result {
                        case .failure(let error):
                            return self.checkThenHandlePaymentFailureAndRetryPayment(error,
                                                                                     alertProvider: paymentAlerts,
                                                                                     paymentGatewayAccount: paymentGatewayAccount,
                                                                                     channel: channel,
                                                                                     paymentIntentForRecovery: paymentIntentForRecovery,
                                                                                     onCompletion: onCompletion)
                        case .success:
                            self.paymentOrchestrator.retryPayment(for: self.order) { [weak self] result in
                                guard let self else { return }
                                switch result {
                                case .success(let capturedPaymentData):
                                    self.handleSuccessfulPayment(capturedPaymentData: capturedPaymentData)
                                    onCompletion(.success(capturedPaymentData))
                                case .failure(CardReaderServiceError.paymentMethodCollection(.commandCancelled(let cancellationSource))):
                                    self.handlePaymentMethodCollectionCancellation(cancellationSource, alertProvider: paymentAlerts)
                                case .failure(let error):
                                    self.checkThenHandlePaymentFailureAndRetryPayment(error,
                                                                                      alertProvider: paymentAlerts,
                                                                                      paymentGatewayAccount: paymentGatewayAccount,
                                                                                      channel: channel,
                                                                                      paymentIntentForRecovery: paymentIntentForRecovery,
                                                                                      onCompletion: onCompletion)
                                }
                            }
                        }
                    }
                }, dismissCompletion: { [weak self] in
                    guard let self else {
                        return onCompletion(.failure(error))
                    }
                    self.completeAfterErrorDismissal(error, onCompletion: onCompletion)
                })
        )
    }

    private func presentNonRetryableError(error: Error,
                                          paymentAlerts: any CardReaderTransactionAlertsProviding<AlertPresenter.AlertDetails>,
                                          receiptState: CardReaderTransactionFailureAlertReceiptState,
                                          onCompletion: @escaping (Result<CardPresentCapturedPaymentData, Error>) -> ()) {
        let dismissCompletion: () -> Void = { [weak self] in
            guard let self else {
                return onCompletion(.failure(error))
            }
            self.completeAfterErrorDismissal(error, onCompletion: onCompletion)
        }

        alertsPresenter.present(viewModel: paymentAlerts.nonRetryableError(error: error,
                                                                           receiptState: receiptState,
                                                                           dismissCompletion: dismissCompletion))
    }

    /// Cancels payment and record analytics.
    ///
    func cancelPayment(from cancelationSource: WooAnalyticsEvent.InPersonPayments.CancellationSource,
                       alertProvider paymentAlerts: any CardReaderTransactionAlertsProviding<AlertPresenter.AlertDetails>,
                       onCompleted: @escaping () -> ()) {
        paymentFlowLock.lock()
        defer { paymentFlowLock.unlock() }
        paymentFlowCanceled = true
        paymentOrchestrator.cancelPayment { [weak self] result in
            switch result {
            case .success:
                self?.analyticsTracker.trackPaymentCancelation(cancelationSource: cancelationSource)
                guard let self else { return onCompleted() }
                self.completeCancellationWhenApplicationIsActive(alertProvider: paymentAlerts, onCompleted: onCompleted)
            case .failure(CardReaderServiceError.paymentCancellation(.noActivePaymentIntent)):
                // The synchronized start gate guarantees no Hardware attempt can begin after this cancellation.
                self?.analyticsTracker.trackPaymentCancelation(cancelationSource: cancelationSource)
                guard let self else { return onCompleted() }
                self.completeCancellationWhenApplicationIsActive(alertProvider: paymentAlerts, onCompleted: onCompleted)
            case .failure(let error):
                DDLogWarn("💳 Failed to cancel payment after merchant cancellation: \(error)")
                self?.setPaymentFlowCanceled(false)
            }
        }
    }

    func completeCancellationWhenApplicationIsActive(
        alertProvider paymentAlerts: any CardReaderTransactionAlertsProviding<AlertPresenter.AlertDetails>,
        onCompleted: @escaping () -> Void
    ) {
        if applicationStateProvider() == .active {
            deliverCancellationCompletion(onCompleted)
            return
        }

        applicationReactivationCancellable = notificationCenter
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .prefix(1)
            .sink { [weak self] _ in
                self?.presentPaymentCancellationConfirmationIfAvailable(alertProvider: paymentAlerts, onCompleted: onCompleted)
            }

        // Catch an activation that landed between the initial state check and installing the subscription.
        if applicationStateProvider() == .active {
            presentPaymentCancellationConfirmationIfAvailable(alertProvider: paymentAlerts, onCompleted: onCompleted)
        }
    }

    func presentPaymentCancellationConfirmationIfAvailable(
        alertProvider paymentAlerts: any CardReaderTransactionAlertsProviding<AlertPresenter.AlertDetails>,
        onCompleted: @escaping () -> Void
    ) {
        guard let confirmation = paymentAlerts.paymentCancellationConfirmation(onDismiss: { [weak self] in
            guard let self else { return onCompleted() }
            self.deliverCancellationCompletion(onCompleted)
        }) else {
            deliverCancellationCompletion(onCompleted)
            return
        }

        paymentFlowLock.lock()
        guard cancellationOutcomeState == .pending else {
            paymentFlowLock.unlock()
            return
        }
        cancellationOutcomeState = .awaitingConfirmation
        paymentFlowLock.unlock()

        applicationReactivationCancellable?.cancel()
        applicationReactivationCancellable = nil
        alertsPresenter.present(viewModel: confirmation)
    }

    func deliverCancellationCompletion(_ onCompleted: @escaping () -> Void) {
        paymentFlowLock.lock()
        guard cancellationOutcomeState != .completed else {
            paymentFlowLock.unlock()
            return
        }
        cancellationOutcomeState = .completed
        paymentFlowLock.unlock()

        applicationReactivationCancellable?.cancel()
        applicationReactivationCancellable = nil
        onCompleted()
    }

    func setPaymentFlowCanceled(_ canceled: Bool) {
        paymentFlowLock.lock()
        defer { paymentFlowLock.unlock() }
        paymentFlowCanceled = canceled
        if canceled == false {
            cancellationOutcomeState = .pending
        }
    }

    func lockPaymentFlowForStart() -> Bool {
        paymentFlowLock.lock()
        guard paymentFlowCanceled == false else {
            paymentFlowLock.unlock()
            return false
        }
        return true
    }

    private func cancelPaymentAndComplete(with error: Error,
                                          onCompletion: @escaping (Result<CardPresentCapturedPaymentData, Error>) -> ()) {
        paymentOrchestrator.cancelPayment { result in
            if case .failure(let cancellationError) = result {
                DDLogWarn("💳 Failed to cancel payment after payment error dismissal: \(cancellationError)")
            }
            onCompletion(.failure(error))
        }
    }

    private func completeAfterErrorDismissal(_ error: Error,
                                             onCompletion: @escaping (Result<CardPresentCapturedPaymentData, Error>) -> ()) {
        guard shouldCancelPaymentAfterDismissing(error) else {
            return onCompletion(.failure(error))
        }

        cancelPaymentAndComplete(with: error, onCompletion: onCompletion)
    }

    private func shouldCancelPaymentAfterDismissing(_ error: Error) -> Bool {
        switch error {
        case ServerSidePaymentCaptureError.terminalPaymentPreparation:
            return true
        case let cardReaderError as CardReaderServiceError:
            return cardReaderError.shouldCancelPaymentAfterDismissal
        default:
            return false
        }
    }

    /// Allow merchants to print or email backend-generated receipts.
    ///
    func presentBackendReceiptAlert(alertProvider paymentAlerts: any CardReaderTransactionAlertsProviding<AlertPresenter.AlertDetails>,
                                    paymentMethod: PaymentMethod?,
                                    onCompleted: @escaping () -> ()) {
        // Handles receipt presentation for both print and native iOS client email actions
        let presentBackendReceiptAction: () -> Void = { [weak self] in
            guard let self else { return }

            alertsPresenter.dismiss()
            paymentOrchestrator.presentBackendReceipt(for: self.order, onCompletion: { [weak self] result in
                guard let self else { return }

                switch result {
                case let .success(receipt):
                    presentBackendReceiptModally(receipt: receipt, paymentMethod: paymentMethod, onCompleted: onCompleted)
                case let .failure(error):
                    presentReceiptFailedNotice(with: error, onCompleted: onCompleted)
                }
            })
        }

        getReceiptStateForSuccessPayment(presentBackendReceiptAction: presentBackendReceiptAction,
                                         noReceiptAction: onCompleted,
                                         paymentMethod: paymentMethod,
                                         completion: { [weak self] receiptState in
            guard let self else { return }

            alertsPresenter.present(viewModel: paymentAlerts.success(receiptState: receiptState))
        })
    }

    func storeInPersonPaymentsTransactionDateIfFirst(using cardReaderType: CardReaderType) {
        stores.dispatch(AppSettingsAction.storeInPersonPaymentsTransactionIfFirst(siteID: order.siteID,
                                                                                  cardReaderType: cardReaderType))
    }
}

// MARK: Backend receipts presentation
private extension CollectOrderPaymentUseCase {
    /// Prepares and presents the backend receipt modally
    ///
    func presentBackendReceiptModally(receipt: Receipt, paymentMethod: PaymentMethod?, onCompleted: @escaping (() -> Void)) {
        let receiptViewModel = ReceiptViewModel(receipt: receipt,
                                                orderID: order.orderID,
                                                siteName: stores.sessionManager.defaultSite?.name,
                                                currency: order.currency,
                                                paymentMethod: paymentMethod)
        let receiptViewController = ReceiptViewController(viewModel: receiptViewModel, onDisappear: {
            onCompleted()
        })
        let navigationController = UINavigationController(rootViewController: receiptViewController)
        rootViewController.present(navigationController, animated: true)
    }

    func presentReceiptFailedNotice(with error: Error?, onCompleted: @escaping (() -> Void)) {
        // TODO: consider removing this under #12864, when we have some other way to handle notices.
        guard let rootViewController = rootViewController as? UIViewController else {
            return
        }

        DDLogError("Failed to present receipt for order: \(order.orderID). Site \(order.siteID). Error: \(String(describing: error))")

        let noticePresenter = DefaultNoticePresenter()
        let notice = Notice(title: CollectOrderPaymentUseCaseDefinitions.Localization.failedReceiptPrintNoticeText,
                            feedbackType: .error)
        noticePresenter.presentingViewController = rootViewController
        noticePresenter.enqueue(notice: notice)

        onCompleted()
    }
}

// MARK: - Collect customer email and send receipt after payment presentation
private extension CollectOrderPaymentUseCase {
    func presentSendReceiptAfterPayment(paymentMethod: PaymentMethod?, onCompleted: @escaping ((Order?) -> Void)) {
        let coordinator = CardPresentPaymentReceiptEmailCoordinator(countryCode: configuration.countryCode,
                                                                    cardReaderModel: analyticsTracker.connectedReaderModel,
                                                                    currency: order.currency,
                                                                    paymentMethod: paymentMethod)
        receiptEmailCoordinator = coordinator

        let viewController = rootViewController.presentedViewController ?? rootViewController
        coordinator.presentSendReceiptAfterPayment(from: viewController, order: order) { [weak self] order in
            self?.receiptEmailCoordinator = nil
            onCompleted(order)
        }
    }

    private func getReceiptStateForSuccessPayment(
        presentBackendReceiptAction: @escaping () -> Void,
        noReceiptAction: @escaping () -> Void,
        paymentMethod: PaymentMethod?,
        completion: @escaping (CardReaderTransactionAlertReceiptState) -> Void) {
        receiptEligibilityUseCase.isEligibleForSuccessfulPaymentEmailReceipts { isEligibleSendingReceiptAfterPayment in
            let receiptState: CardReaderTransactionAlertReceiptState

            if let email = self.order.billingAddress?.email, email.isNotEmpty {
                receiptState = .paymentSuccessEmailSent(email: email,
                                                        printReceiptAction: presentBackendReceiptAction,
                                                        noReceiptAction: noReceiptAction)
            } else if isEligibleSendingReceiptAfterPayment {
                receiptState = .promptToSendEmailReceipt(printReceiptAction: presentBackendReceiptAction,
                                                         emailReceiptAction: { [weak self] in
                    guard let self else { return }
                    self.presentSendReceiptAfterPayment(paymentMethod: paymentMethod) { order in
                        if let order, let email = order.billingAddress?.email, email.isNotEmpty {
                            self.order = order
                            completion(.paymentSuccessEmailSent(email: email,
                                                                printReceiptAction: presentBackendReceiptAction,
                                                                noReceiptAction: noReceiptAction))
                        }
                    }
                },
                                                         noReceiptAction: noReceiptAction)
            } else {
                receiptState = .emailSendingNotSupported(printReceiptAction: presentBackendReceiptAction,
                                                         noReceiptAction: noReceiptAction)
            }

            completion(receiptState)
        }
    }

    private func getReceiptStateForFailedPayment(error: Error,
                                                 paymentGatewayID: String,
                                                 completion: @escaping (CardReaderTransactionFailureAlertReceiptState) -> Void) {
        let isErrorEligibleForSendingFailureReceiptAfterPayment: Bool = {
            switch error {
            case CardReaderServiceError.paymentCaptureWithPaymentMethod(.paymentDeclinedByPaymentProcessorAPI, _),
                CardReaderServiceError.paymentCapture(.paymentDeclinedByPaymentProcessorAPI):
                return true
            default:
                return false
            }
        }()

        // Order only fails when the payment is declined by the payment processor, other types of failure don't produce failure states and receipts.
        guard isErrorEligibleForSendingFailureReceiptAfterPayment else {
            return completion(.noEmailReceipt)
        }

        receiptEligibilityUseCase.isEligibleForFailedPaymentEmailReceipts(paymentGatewayID: paymentGatewayID) { [weak self] isEligible in
            guard let self else { return }

            let receiptState: CardReaderTransactionFailureAlertReceiptState
            if isEligible {
                if let email = order.billingAddress?.email, email.isNotEmpty {
                    receiptState = .paymentSuccessEmailSent(email: email)
                } else {
                    receiptState = .promptToSendEmailReceipt(emailReceiptAction: { [weak self] in
                        guard let self else { return }
                        presentSendReceiptAfterPayment(paymentMethod: nil) { [weak self] order in
                            guard let self else { return }
                            if let order, let email = order.billingAddress?.email, email.isNotEmpty {
                                self.order = order
                                completion(.paymentSuccessEmailSent(email: email))
                            }
                        }
                    })
                }
            } else {
                receiptState = .noEmailReceipt
            }
            completion(receiptState)
        }
    }
}

// MARK: Interac handling
private extension CollectOrderPaymentUseCase {
    /// For certain payment methods like Interac in Canada, the payment is captured on the client side (customer is charged).
    /// To prevent the order from multiple charges after the first client side success, the order is marked as paid locally in case of any
    /// potential failures until the next order refresh.
    func markOrderAsPaidIfNeeded(intent: PaymentIntent) {
        guard let paymentMethod = intent.paymentMethod() else {
            return
        }
        switch paymentMethod {
        case .interacPresent:
            let action = OrderAction.markOrderAsPaidLocally(siteID: order.siteID, orderID: order.orderID, datePaid: Date()) { _ in }
            stores.dispatch(action)
        default:
            return
        }
    }
}

// MARK: Definitions
private enum CollectOrderPaymentUseCaseDefinitions {
    /// Mailing a receipt failed but the SDK didn't return a more specific error
    ///
    struct UnknownEmailError: Error {}


    enum Localization {
        static let failedReceiptPrintNoticeText = NSLocalizedString(
            "OrderDetailsViewModel.displayReceiptRetrievalErrorNotice.notice",
            value: "Unable to retrieve receipt.",
            comment: "Notice that appears when no receipt can be retrieved upon tapping on 'See receipt' in the Order Details view.")

        private static let emailSubjectWithStoreName = NSLocalizedString("Your receipt from %1$@",
                                                                 comment: "Subject of email sent with a card present payment receipt")
        private static let emailSubjectWithoutStoreName = NSLocalizedString("Your receipt",
                                                                    comment: "Subject of email sent with a card present payment receipt")
        static func emailSubject(storeName: String?) -> String {
            guard let storeName, storeName.isNotEmpty else {
                return emailSubjectWithoutStoreName
            }
            return .localizedStringWithFormat(emailSubjectWithStoreName, storeName)
        }

        private static let collectPaymentWithoutName = NSLocalizedString("Collect payment",
                                                                 comment: "Alert title when starting the collect payment flow without a user name.")
        private static let collectPaymentWithName = NSLocalizedString("Collect payment from %1$@",
                                                                 comment: "Alert title when starting the collect payment flow with a user name.")
        static func collectPaymentTitle(username: String?) -> String {
            guard let username, username.isNotEmpty else {
                return collectPaymentWithoutName
            }
            return .localizedStringWithFormat(collectPaymentWithName, username)
        }

        private static let processingPaymentWithoutName = NSLocalizedString(
            "Processing payment",
            comment: "Alert title when processing a payment without a user name.")
        private static let processingPaymentWithName = NSLocalizedString(
            "Processing payment from %1$@",
            comment: "Alert title when processing a payment with a user name.")
        static func processingPaymentTitle(username: String?) -> String {
            guard let username, username.isNotEmpty else {
                return processingPaymentWithoutName
            }
            return .localizedStringWithFormat(processingPaymentWithName, username)
        }
    }
}

enum CardPaymentRetryApproach {
    case reuseIntent
    case restart
    case dontRetry
}

protocol CardPaymentErrorProtocol: Error {
    var retryApproach: CardPaymentRetryApproach { get }
    var requiresFallbackPaymentMethod: Bool { get }
}

private extension SiteAPI {
    var hasTerminalPaymentPreparationRoute: Bool {
        routes.contains { route in
            route.hasPrefix(Constants.prepareTerminalPaymentRoutePrefix) &&
            route.hasSuffix(Constants.prepareTerminalPaymentRouteSuffix)
        }
    }

    enum Constants {
        static let prepareTerminalPaymentRoutePrefix = "/wc/v3/payments/orders/"
        static let prepareTerminalPaymentRouteSuffix = "/prepare_terminal_payment"
    }
}

extension CardReaderServiceError: CardPaymentErrorProtocol {
    var shouldCancelPaymentAfterDismissal: Bool {
        switch self {
        case .paymentMethodCollection(let underlyingError), .paymentCapture(let underlyingError), .paymentCaptureWithPaymentMethod(let underlyingError, _):
            return canRetryPayment(underlyingError: underlyingError)
        default:
            return false
        }
    }

    var retryApproach: CardPaymentRetryApproach {
        switch self {
        case .paymentMethodCollection(let underlyingError), .paymentCapture(let underlyingError), .paymentCaptureWithPaymentMethod(let underlyingError, _):
            guard canRetryPayment(underlyingError: underlyingError) else {
                return .dontRetry
            }
            return .reuseIntent
        case .retryNotPossibleUnknownCause,
                .retryNotPossibleNoActivePayment,
                .retryNotPossibleProcessingInProgress,
                .retryNotPossibleActivePaymentCancelled,
                .retryNotPossibleActivePaymentSucceeded,
                .paymentCancellation:
            return .dontRetry
        default:
            return .restart
        }
    }

    var requiresFallbackPaymentMethod: Bool {
        switch self {
        case .paymentCaptureWithPaymentMethod(.paymentDeclinedByPaymentProcessorAPI(declineReason: .pinRequired), _),
                .paymentCapture(.paymentDeclinedByPaymentProcessorAPI(declineReason: .pinRequired)):
            return true
        default:
            return false
        }
    }

    private func canRetryPayment(underlyingError: UnderlyingError) -> Bool {
        switch underlyingError {
        case .notConnectedToReader,
                .commandNotAllowedDuringCall,
                .featureNotAvailableWithConnectedReader,
                .paymentMethodCollectionTimedOut:
            return false
        default:
            return true
        }
    }
}

extension CollectOrderPaymentUseCaseError: CardPaymentErrorProtocol {
    var retryApproach: CardPaymentRetryApproach {
        switch self {
        case .flowCanceledByUser, .orderAlreadyPaid, .orderTotalChanged:
            return .dontRetry
        case .paymentGatewayNotFound:
            return .restart
        case .couldNotRefreshOrder:
            return .reuseIntent
        }
    }

    var requiresFallbackPaymentMethod: Bool {
        false
    }
}

extension ServerSidePaymentCaptureError: CardPaymentErrorProtocol {
    var retryApproach: CardPaymentRetryApproach {
        switch self {
        case .terminalPaymentPreparation:
            return .reuseIntent
        case .paymentGateway, .paymentIntentNotSuccessful:
            return .dontRetry
        }
    }

    var requiresFallbackPaymentMethod: Bool {
        false
    }
}
