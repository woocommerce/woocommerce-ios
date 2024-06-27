import Yosemite
import PassKit
import WooFoundation

/// Contains data associated with a payment that has been collected, processed, and captured.
struct CardPresentCapturedPaymentData {
    /// Currently used for analytics.
    let paymentMethod: PaymentMethod

    /// Used for receipt generation for display in the app.
    let receiptParameters: CardPresentReceiptParameters?
}

protocol PaymentCaptureOrchestrating {
    func collectPayment(for order: Order,
                        orderTotal: NSDecimalNumber,
                        paymentGatewayAccount: PaymentGatewayAccount,
                        paymentMethodTypes: [String],
                        stripeSmallestCurrencyUnitMultiplier: Decimal,
                        onPreparingReader: @escaping () -> Void,
                        onWaitingForInput: @escaping (CardReaderInput) -> Void,
                        onProcessingMessage: @escaping () -> Void,
                        onDisplayMessage: @escaping (String) -> Void,
                        onProcessingCompletion: @escaping (PaymentIntent) -> Void,
                        onCompletion: @escaping (Result<CardPresentCapturedPaymentData, Error>) -> Void)

    func retryPayment(for order: Order,
                      onCompletion: @escaping (Result<CardPresentCapturedPaymentData, Error>) -> Void)

    func cancelPayment(onCompletion: @escaping (Result<Void, Error>) -> Void)

    func emailReceipt(for order: Order, params: CardPresentReceiptParameters, onContent: @escaping (String) -> Void)

    func saveReceipt(for order: Order, params: CardPresentReceiptParameters)

    func presentBackendReceipt(for order: Order, onCompletion: @escaping (Result<Receipt, Error>) -> Void)
}



/// Orchestrates the sequence of actions required to capture a payment:
/// 1. Triggers the `preparingReader` alert
/// 2. Creates the payment intent parameters
/// 3. Controls (prevents during payment) wallet presentation: we don't want to use the merchant's Apple Pay for their customer's purchase!
/// 4. Obtain a Payment Intent from the card reader (i.e., create a payment intent, collect a payment method, and process the payment)
/// 5. Submit the Payment Intent to WCPay to capture a payment
final class PaymentCaptureOrchestrator: PaymentCaptureOrchestrating {
    private let currencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)
    private let personNameComponentsFormatter = PersonNameComponentsFormatter()
    private let paymentReceiptEmailParameterDeterminer: ReceiptEmailParameterDeterminer

    private let celebration: PaymentCaptureCelebrationProtocol

    private var walletSuppressionRequestToken: PKSuppressionRequestToken?

    private let stores: StoresManager

    init(stores: StoresManager = ServiceLocator.stores,
         paymentReceiptEmailParameterDeterminer: ReceiptEmailParameterDeterminer = PaymentReceiptEmailParameterDeterminer(),
         celebration: PaymentCaptureCelebrationProtocol = PaymentCaptureCelebration()) {
        self.stores = stores
        self.paymentReceiptEmailParameterDeterminer = paymentReceiptEmailParameterDeterminer
        self.celebration = celebration
    }

    private var handlersForActivePayment: PaymentHandlers? = nil

    func collectPayment(for order: Order,
                        orderTotal: NSDecimalNumber,
                        paymentGatewayAccount: PaymentGatewayAccount,
                        paymentMethodTypes: [String],
                        stripeSmallestCurrencyUnitMultiplier: Decimal,
                        onPreparingReader: @escaping () -> Void,
                        onWaitingForInput: @escaping (CardReaderInput) -> Void,
                        onProcessingMessage: @escaping () -> Void,
                        onDisplayMessage: @escaping (String) -> Void,
                        onProcessingCompletion: @escaping (PaymentIntent) -> Void,
                        onCompletion: @escaping (Result<CardPresentCapturedPaymentData, Error>) -> Void) {
        handlersForActivePayment = PaymentHandlers(onPreparingReader: onPreparingReader,
                                                   onWaitingForInput: onWaitingForInput,
                                                   onProcessingMessage: onProcessingMessage,
                                                   onDisplayMessage: onDisplayMessage,
                                                   onProcessingCompletion: onProcessingCompletion)
        onPreparingReader()

        let parameters = paymentParameters(order: order,
                                           orderTotal: orderTotal,
                                           country: paymentGatewayAccount.country,
                                           statementDescriptor: paymentGatewayAccount.statementDescriptor,
                                           paymentMethodTypes: paymentMethodTypes,
                                           stripeSmallestCurrencyUnitMultiplier: stripeSmallestCurrencyUnitMultiplier)

        /// Briefly suppress pass (wallet) presentation so that the merchant doesn't attempt to pay for the buyer's order when the
        /// reader begins to collect payment.
        ///
        suppressPassPresentation()

        let paymentAction = CardPresentPaymentAction.collectPayment(
            siteID: order.siteID,
            orderID: order.orderID,
            parameters: parameters,
            onCardReaderMessage: { event in
                switch event {
                case .waitingForInput(let inputMethods):
                    onWaitingForInput(inputMethods)
                case .displayMessage(let message):
                    onDisplayMessage(message)
                case .cardDetailsCollected, .cardRemovedAfterClientSidePaymentCapture:
                    onProcessingMessage()
                case .cardInserted, .cardRemoved, .lowBattery, .lowBatteryResolved, .disconnected:
                    DDLogInfo("💳 Unhandled card reader event received: \(event)")
                }
            },
            onProcessingCompletion: { intent in
                onProcessingCompletion(intent)
            },
            onCompletion: { [weak self] result in
                self?.allowPassPresentation()
                self?.completePaymentIntentCapture(
                    order: order,
                    captureResult: result,
                    onCompletion: onCompletion
                )
            }
        )

        stores.dispatch(paymentAction)
    }

    func retryPayment(for order: Order,
                      onCompletion: @escaping (Result<CardPresentCapturedPaymentData, Error>) -> Void) {
        guard let handlers = handlersForActivePayment else {
            return onCompletion(.failure(PaymentCaptureOrchestratorError.couldNotRetryPayment))
        }

        handlers.onPreparingReader()

        let retryPaymentAction = CardPresentPaymentAction.retryPayment(
            siteID: order.siteID,
            orderID: order.orderID,
            onCardReaderMessage: { event in
                switch event {
                case .waitingForInput(let inputMethods):
                    handlers.onWaitingForInput(inputMethods)
                case .displayMessage(let message):
                    handlers.onDisplayMessage(message)
                case .cardDetailsCollected, .cardRemovedAfterClientSidePaymentCapture:
                    handlers.onProcessingMessage()
                case .cardInserted, .cardRemoved, .lowBattery, .lowBatteryResolved, .disconnected:
                    DDLogInfo("💳 Unhandled card reader event received during retry: \(event)")
                }
            },
            onProcessingCompletion: { intent in
                handlers.onProcessingCompletion(intent)
            },
            onCompletion: { [weak self] result in
                self?.allowPassPresentation()
                self?.completePaymentIntentCapture(
                    order: order,
                    captureResult: result,
                    onCompletion: onCompletion
                )
            })

        stores.dispatch(retryPaymentAction)
    }

    func cancelPayment(onCompletion: @escaping (Result<Void, Error>) -> Void) {
        let action = CardPresentPaymentAction.cancelPayment() { [weak self] result in
            self?.allowPassPresentation()
            onCompletion(result)
        }
        stores.dispatch(action)
    }

    func emailReceipt(for order: Order, params: CardPresentReceiptParameters, onContent: @escaping (String) -> Void) {
        let action = ReceiptAction.generateContent(order: order, parameters: params) { emailContent in
            onContent(emailContent)
        }

        stores.dispatch(action)
    }

    func presentBackendReceipt(for order: Order, onCompletion: @escaping (Result<Receipt, Error>) -> Void) {
        let action = ReceiptAction.retrieveReceipt(order: order) { result in
            switch result {
            case let .success(receipt):
                onCompletion(.success(receipt))
            case let .failure(error):
                onCompletion(.failure(error))
            }
        }
        stores.dispatch(action)
    }

    func saveReceipt(for order: Order, params: CardPresentReceiptParameters) {
        let action = ReceiptAction.saveReceipt(order: order, parameters: params)

        stores.dispatch(action)
    }
}

private extension PaymentCaptureOrchestrator {
    /// Suppress wallet presentation. This requires a special entitlement from Apple:
    /// `com.apple.developer.passkit.pass-presentation-suppression`
    /// See Woo-*.entitlements in WooCommerce/Resources
    ///
    func suppressPassPresentation() {
        /// iPads don't support NFC passes. Attempting to call `requestAutomaticPassPresentationSuppression` on them will
        /// return 0 `notSupported`
        ///
        guard !UIDevice.isPad() else {
            return
        }

        guard !PKPassLibrary.isSuppressingAutomaticPassPresentation() else {
            return
        }

        walletSuppressionRequestToken = PKPassLibrary.requestAutomaticPassPresentationSuppression() { result in
            guard result == .success else {
                DDLogWarn("Automatic pass presentation suppression request failed. Reason: \(result.rawValue)")

                let logProperties: [String: Any] = ["PKAutomaticPassPresentationSuppressionResult": result.rawValue]
                ServiceLocator.crashLogging.logMessage(
                    "Automatic pass presentation suppression request failed",
                    properties: logProperties,
                    level: .warning
                )
                return
            }
        }
    }

    /// Restore wallet presentation.
    func allowPassPresentation() {
        /// iPads don't have passes (wallets) to present
        ///
        guard !UIDevice.isPad() else {
            return
        }

        guard let walletSuppressionRequestToken = walletSuppressionRequestToken, walletSuppressionRequestToken != 0 else {
            return
        }

        PKPassLibrary.endAutomaticPassPresentationSuppression(withRequestToken: walletSuppressionRequestToken)
    }
}

private extension PaymentCaptureOrchestrator {
    func completePaymentIntentCapture(order: Order,
                                    captureResult: Result<PaymentIntent, Error>,
                                    onCompletion: @escaping (Result<CardPresentCapturedPaymentData, Error>) -> Void) {
        switch captureResult {
        case .failure(let error):
            onCompletion(.failure(error))
        case .success(let paymentIntent):
            guard let paymentMethod = paymentIntent.paymentMethod(),
                  let receiptParameters = paymentIntent.receiptParameters() else {
                let error = CardReaderServiceError.paymentCapture()

                DDLogError("⛔️ Payment completed without required metadata: \(error)")

                onCompletion(.failure(error))
                return
            }

            celebrate() // plays a sound, haptic
            saveReceipt(for: order, params: receiptParameters)
            onCompletion(.success(.init(paymentMethod: paymentMethod,
                                        receiptParameters: receiptParameters)))
            self.handlersForActivePayment = nil
        }
    }

    func paymentParameters(order: Order,
                           orderTotal: NSDecimalNumber,
                           country: String,
                           statementDescriptor: String?,
                           paymentMethodTypes: [String],
                           stripeSmallestCurrencyUnitMultiplier: Decimal) -> PaymentParameters {
        let metadata = PaymentIntent.initMetadata(
            store: stores.sessionManager.defaultSite?.name,
            customerName: buildCustomerNameFromBillingAddress(order.billingAddress),
            customerEmail: order.billingAddress?.email,
            siteURL: stores.sessionManager.defaultSite?.url,
            orderID: order.orderID,
            paymentType: PaymentIntent.PaymentTypes.single
        )

        return PaymentParameters(amount: orderTotal as Decimal,
                                 currency: order.currency,
                                 stripeSmallestCurrencyUnitMultiplier: stripeSmallestCurrencyUnitMultiplier,
                                 applicationFee: applicationFee(for: orderTotal, country: country),
                                 receiptDescription: receiptDescription(orderNumber: order.number),
                                 statementDescription: statementDescriptor,
                                 receiptEmail: paymentReceiptEmailParameterDeterminer.receiptEmail(from: order),
                                 paymentMethodTypes: paymentMethodTypes,
                                 metadata: metadata)
    }

    private func applicationFee(for orderTotal: NSDecimalNumber, country: String) -> Decimal? {
        guard country.uppercased() == CountryCode.CA.rawValue else {
            return nil
        }

        let fee = orderTotal.multiplying(by: Constants.canadaPercentageFee).adding(Constants.canadaFlatFee)

        let numberHandler = NSDecimalNumberHandler(roundingMode: .plain,
                                                   scale: 2,
                                                   raiseOnExactness: false,
                                                   raiseOnOverflow: false,
                                                   raiseOnUnderflow: false,
                                                   raiseOnDivideByZero: false)
        return fee.rounding(accordingToBehavior: numberHandler) as Decimal
    }

    func receiptDescription(orderNumber: String) -> String? {
        guard let storeName = stores.sessionManager.defaultSite?.name,
              let blogID = stores.sessionManager.defaultSite?.siteID else {
            return nil
        }

        return String.localizedStringWithFormat(Localization.receiptDescription,
                                                orderNumber,
                                                storeName,
                                                String(blogID))
    }

    func celebrate() {
        celebration.celebrate()
    }

    private func buildCustomerNameFromBillingAddress(_ address: Address?) -> String {
        var personNameComponents = PersonNameComponents()
        personNameComponents.givenName = address?.firstName
        personNameComponents.familyName = address?.lastName
        return personNameComponentsFormatter.string(from: personNameComponents)
    }
}

private extension PaymentCaptureOrchestrator {
    enum Constants {
        static let canadaFlatFee = NSDecimalNumber(string: "0.15")
        static let canadaPercentageFee = NSDecimalNumber(0)
    }
}

private extension PaymentCaptureOrchestrator {
    enum Localization {
        static let receiptDescription = NSLocalizedString(
            "In-Person Payment for Order #%1$@ for %2$@ blog_id %3$@",
            comment: "Message included in emailed receipts. " +
            "Reads as: In-Person Payment for Order @{number} for @{store name} blog_id @{blog ID} " +
            "Parameters: %1$@ - order number, %2$@ - store name, %3$@ - blog ID number")
    }
}

private enum PaymentCaptureOrchestratorError: LocalizedError {
    case couldNotRetryPayment

    var errorDescription: String? {
        switch self {
        case .couldNotRetryPayment:
            return NSLocalizedString(
                "There was an error retrying this payment. Please go back and start again.",
                comment: "Error shown when there's an unrecoverable issue while retrying a payment, and it needs to be" +
                "restarted from the beginning.")
        }
    }
}

private extension PaymentCaptureOrchestrator {
    struct PaymentHandlers {
        let onPreparingReader: () -> Void
        let onWaitingForInput: (CardReaderInput) -> Void
        let onProcessingMessage: () -> Void
        let onDisplayMessage: (String) -> Void
        let onProcessingCompletion: (PaymentIntent) -> Void
    }
}
