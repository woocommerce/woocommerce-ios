import Yosemite
import PassKit

/// Orchestrates the sequence of actions required to capture a payment:
/// 1. Check if there is a card reader connected
/// 2. Launch the reader discovering and pairing UI if there is no reader connected
/// 3. Obtain a Payment Intent from the card reader (i.e., create a payment intent, collect a payment method, and process the payment)
/// 4. Submit the Payment Intent to WCPay to capture a payment
/// Steps 1 and 2 will be implemented as part of https://github.com/woocommerce/woocommerce-ios/issues/4062
final class PaymentCaptureOrchestrator {
    private let currencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)
    private let personNameComponentsFormatter = PersonNameComponentsFormatter()

    private let celebration = PaymentCaptureCelebration()

    private var walletSuppressionRequestToken: PKSuppressionRequestToken?

    func collectPayment(for order: Order,
                        statementDescriptor: String?,
                        onWaitingForInput: @escaping () -> Void,
                        onProcessingMessage: @escaping () -> Void,
                        onDisplayMessage: @escaping (String) -> Void,
                        onCompletion: @escaping (Result<CardPresentReceiptParameters, Error>) -> Void) {
        /// Bail out if the order amount is below the minimum allowed:
        /// https://stripe.com/docs/currencies#minimum-and-maximum-charge-amounts
        guard isTotalAmountValid(order: order) else {
            DDLogError("💳 Error: failed to capture payment for order. Order amount is below minimum")
            onCompletion(.failure(minimumAmountError(order: order, minimumAmount: Constants.minimumAmount)))
            return
        }
        /// First ask the backend to create/assign a Stripe customer for the order
        ///
        var customerID: String?
        let customerAction = PaymentGatewayAccountAction.fetchOrderCustomer(siteID: order.siteID, orderID: order.orderID) { [self] result in
            switch result {
            case .success(let customer):
                customerID = customer.id
            case .failure:
                // It is not ideal but ok to proceed to payment intent creation without a customer ID
                DDLogWarn("Warning: failed to fetch customer ID for an order")
            }

            guard let parameters = paymentParameters(
                    order: order,
                    statementDescriptor: statementDescriptor,
                    customerID: customerID
            ) else {
                DDLogError("Error: failed to create payment parameters for an order")
                onCompletion(.failure(CardReaderServiceError.paymentCapture()))
                return
            }

            /// Briefly suppress pass (wallet) presentation so that the merchant doesn't attempt to pay for the buyer's order when the
            /// reader begins to collect payment.
            ///
            suppressPassPresentation()

            let paymentAction = CardPresentPaymentAction.collectPayment(
                siteID: order.siteID,
                orderID: order.orderID,
                parameters: parameters,
                onCardReaderMessage: { (event) in
                    switch event {
                    case .waitingForInput:
                        onWaitingForInput()
                    case .displayMessage(let message):
                        onDisplayMessage(message)
                    default:
                        break
                    }
                },
                onCompletion: { [weak self] result in
                    self?.allowPassPresentation()
                    onProcessingMessage()
                    self?.completePaymentIntentCapture(
                        order: order,
                        captureResult: result,
                        onCompletion: onCompletion
                    )
                }
            )

            ServiceLocator.stores.dispatch(paymentAction)
        }

        ServiceLocator.stores.dispatch(customerAction)
    }

    func cancelPayment(onCompletion: @escaping (Result<Void, Error>) -> Void) {
        let action = CardPresentPaymentAction.cancelPayment() { [weak self] result in
            self?.allowPassPresentation()
            onCompletion(result)
        }
        ServiceLocator.stores.dispatch(action)
    }

    func emailReceipt(for order: Order, params: CardPresentReceiptParameters, onContent: @escaping (String) -> Void) {
        let action = ReceiptAction.generateContent(order: order, parameters: params) { emailContent in
            onContent(emailContent)
        }

        ServiceLocator.stores.dispatch(action)
    }

    func saveReceipt(for order: Order, params: CardPresentReceiptParameters) {
        let action = ReceiptAction.saveReceipt(order: order, parameters: params)

        ServiceLocator.stores.dispatch(action)
    }
}

private extension PaymentCaptureOrchestrator {
    /// Supress wallet presentation. This requires a special entitlement from Apple:
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
                                    onCompletion: @escaping (Result<CardPresentReceiptParameters, Error>) -> Void) {
        switch captureResult {
        case .failure(let error):
            onCompletion(.failure(error))
        case .success(let paymentIntent):
            submitPaymentIntent(siteID: order.siteID,
                                order: order,
                                paymentIntent: paymentIntent,
                                onCompletion: onCompletion)
        }
    }

    func submitPaymentIntent(siteID: Int64,
                             order: Order,
                             paymentIntent: PaymentIntent,
                             onCompletion: @escaping (Result<CardPresentReceiptParameters, Error>) -> Void) {
        let action = PaymentGatewayAccountAction.captureOrderPayment(siteID: siteID,
                                                                     orderID: order.orderID,
                                                                     paymentIntentID: paymentIntent.id) { [weak self] result in
            guard let self = self else {
                return
            }

            guard let receiptParameters = paymentIntent.receiptParameters() else {
                let error = CardReaderServiceError.paymentCapture()

                DDLogError("⛔️ Payment completed without required metadata: \(error)")

                onCompletion(.failure(error))
                return
            }

            switch result {
            case .success:
                self.celebrate() // plays a sound, haptic
                self.saveReceipt(for: order, params: receiptParameters)
                onCompletion(.success(receiptParameters))
            case .failure(let error):
                onCompletion(.failure(error))
                return
            }
        }

        ServiceLocator.stores.dispatch(action)
    }

    func paymentParameters(order: Order, statementDescriptor: String?, customerID: String?) -> PaymentParameters? {
        guard let orderTotal = currencyFormatter.convertToDecimal(from: order.total) else {
            DDLogError("Error: attempted to collect payment for an order without a valid total.")
            return nil
        }

        let metadata = PaymentIntent.initMetadata(
            store: ServiceLocator.stores.sessionManager.defaultSite?.name,
            customerName: buildCustomerNameFromBillingAddress(order.billingAddress),
            customerEmail: order.billingAddress?.email,
            siteURL: ServiceLocator.stores.sessionManager.defaultSite?.url,
            orderID: order.orderID,
            paymentType: PaymentIntent.PaymentTypes.single
        )

        return PaymentParameters(amount: orderTotal as Decimal,
                                 currency: order.currency,
                                 receiptDescription: receiptDescription(orderNumber: order.number),
                                 statementDescription: statementDescriptor,
                                 receiptEmail: order.billingAddress?.email,
                                 metadata: metadata,
                                 customerID: customerID)
    }

    func receiptDescription(orderNumber: String) -> String? {
        guard let storeName = ServiceLocator.stores.sessionManager.defaultSite?.name else {
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

private extension PaymentCaptureOrchestrator {
    private enum NotValidAmountError: Error, LocalizedError {
        case belowMinimumAmount(amount: String)
        case other

        public var errorDescription: String? {
            switch self {
            case .belowMinimumAmount(let amount):
                return String.localizedStringWithFormat(Localizations.belowMinimumAmount, amount)
            case .other:
                return Localizations.defaultMessage
            }
        }

        enum Localizations {
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
