import Yosemite
import PassKit

/// Contains data associated with a payment that has been collected, processed, and captured.
struct CardPresentCapturedPaymentData {
    /// Currently used for analytics.
    let paymentMethod: PaymentMethod

    /// Used for receipt generation for display in the app.
    let receiptParameters: CardPresentReceiptParameters
}

/// Orchestrates the sequence of actions required to capture a payment:
/// 1. Check if there is a card reader connected
/// 2. Launch the reader discovering and pairing UI if there is no reader connected
/// 3. Obtain a Payment Intent from the card reader (i.e., create a payment intent, collect a payment method, and process the payment)
/// 4. Submit the Payment Intent to WCPay to capture a payment
/// Steps 1 and 2 will be implemented as part of https://github.com/woocommerce/woocommerce-ios/issues/4062
final class PaymentCaptureOrchestrator {
    private let currencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)
    private let personNameComponentsFormatter = PersonNameComponentsFormatter()
    private let paymentReceiptEmailParameterDeterminer = PaymentReceiptEmailParameterDeterminer()

    private let celebration = PaymentCaptureCelebration()

    private var walletSuppressionRequestToken: PKSuppressionRequestToken?

    private let stores: StoresManager

    init(stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
    }

    func collectPayment(for order: Order,
                        paymentGatewayAccount: PaymentGatewayAccount,
                        paymentMethodTypes: [String],
                        onWaitingForInput: @escaping () -> Void,
                        onProcessingMessage: @escaping () -> Void,
                        onDisplayMessage: @escaping (String) -> Void,
                        onProcessingCompletion: @escaping (PaymentIntent) -> Void,
                        onCompletion: @escaping (Result<CardPresentCapturedPaymentData, Error>) -> Void) {
        /// Bail out if the order amount is below the minimum allowed:
        /// https://stripe.com/docs/currencies#minimum-and-maximum-charge-amounts
        guard isTotalAmountValid(order: order) else {
            DDLogError("💳 Error: failed to capture payment for order. Order amount is below minimum")
            onCompletion(.failure(minimumAmountError(order: order, minimumAmount: Constants.minimumAmount)))
            return
        }

        /// Set state of CardPresentPaymentStore
        ///
        let setAccount = CardPresentPaymentAction.use(paymentGatewayAccount: paymentGatewayAccount)

        stores.dispatch(setAccount)

        paymentParameters(
                order: order,
                statementDescriptor: paymentGatewayAccount.statementDescriptor,
                paymentMethodTypes: paymentMethodTypes
        ) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case let .success(parameters):
                /// Briefly suppress pass (wallet) presentation so that the merchant doesn't attempt to pay for the buyer's order when the
                /// reader begins to collect payment.
                ///
                self.suppressPassPresentation()

                let paymentAction = CardPresentPaymentAction.collectPayment(
                    siteID: order.siteID,
                    orderID: order.orderID,
                    parameters: parameters,
                    onCardReaderMessage: { event in
                        switch event {
                        case .waitingForInput:
                            onWaitingForInput()
                        case .displayMessage(let message):
                            onDisplayMessage(message)
                        case .cardRemovedAfterPaymentCapture:
                            onProcessingMessage()
                        default:
                            break
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

                self.stores.dispatch(paymentAction)
            case let .failure(error):
                onCompletion(Result.failure(error))
            }
        }
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
        }
    }

    func paymentParameters(order: Order,
                           statementDescriptor: String?,
                           paymentMethodTypes: [String],
                           onCompletion: @escaping ((Result<PaymentParameters, Error>) -> Void)) {
        guard let orderTotal = currencyFormatter.convertToDecimal(from: order.total) else {
            DDLogError("Error: attempted to collect payment for an order without a valid total.")
            onCompletion(Result.failure(NotValidAmountError.other))

            return
        }

        paymentReceiptEmailParameterDeterminer.receiptEmail(from: order) { [weak self] result in
            guard let self = self else { return }

            var receiptEmail: String?
            if case let .success(email) = result {
                receiptEmail = email
            }

            let metadata = PaymentIntent.initMetadata(
                store: self.stores.sessionManager.defaultSite?.name,
                customerName: self.buildCustomerNameFromBillingAddress(order.billingAddress),
                customerEmail: order.billingAddress?.email,
                siteURL: self.stores.sessionManager.defaultSite?.url,
                orderID: order.orderID,
                paymentType: PaymentIntent.PaymentTypes.single
            )

            let parameters = PaymentParameters(amount: orderTotal as Decimal,
                                               currency: order.currency,
                                               receiptDescription: self.receiptDescription(orderNumber: order.number),
                                               statementDescription: statementDescriptor,
                                               receiptEmail: receiptEmail,
                                               paymentMethodTypes: paymentMethodTypes,
                                               metadata: metadata)

            onCompletion(Result.success(parameters))
        }
    }

    func receiptDescription(orderNumber: String) -> String? {
        guard let storeName = stores.sessionManager.defaultSite?.name else {
            return nil
        }

        return String.localizedStringWithFormat(Localization.receiptDescription,
                                                orderNumber,
                                                storeName)
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
        /// Minimum order amount in USD:
        /// https://stripe.com/docs/currencies#minimum-and-maximum-charge-amounts
        static let minimumAmount = NSDecimalNumber(string: "0.5")
    }

    func isTotalAmountValid(order: Order) -> Bool {
        guard let orderTotal = currencyFormatter.convertToDecimal(from: order.total) else {
            return false
        }

        return orderTotal as Decimal >= Constants.minimumAmount as Decimal
    }

    func minimumAmountError(order: Order, minimumAmount: NSDecimalNumber) -> Error {
        guard let minimum = currencyFormatter.formatAmount(minimumAmount, with: order.currency) else {
            return NotValidAmountError.other
        }

        return NotValidAmountError.belowMinimumAmount(amount: minimum)
    }
}

private extension PaymentCaptureOrchestrator {
    enum Localization {
        static let receiptDescription = NSLocalizedString("In-Person Payment for Order #%1$@ for %2$@",
                                                          comment: "Message included in emailed receipts. "
                                                            + "Reads as: In-Person Payment for "
                                                            + "Order @{number} for @{store name} "
                                                            + "Parameters: %1$@ - order number, "
                                                            + "%2$@ - store name")
    }
}

extension PaymentCaptureOrchestrator {
    enum NotValidAmountError: Error, LocalizedError {
        case belowMinimumAmount(amount: String)
        case other

        var errorDescription: String? {
            switch self {
            case .belowMinimumAmount(let amount):
                return String.localizedStringWithFormat(Localization.belowMinimumAmount, amount)
            case .other:
                return Localization.defaultMessage
            }
        }

        private enum Localization {
            static let defaultMessage = NSLocalizedString(
                "Unable to process payment. Order total amount is not valid.",
                comment: "Error message when the order amount is not valid."
            )

            static let belowMinimumAmount = NSLocalizedString(
                "Unable to process payment. Order total amount is below the minimum amount you can charge, which is %1$@",
                comment: "Error message when the order amount is below the minimum amount allowed."
            )
        }
    }
}
