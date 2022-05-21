import Combine
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
    private let paymentReceiptEmailParameterDeterminer: ReceiptEmailParameterDeterminer

    private let celebration = PaymentCaptureCelebration()

    private var walletSuppressionRequestToken: PKSuppressionRequestToken?

    private let stores: StoresManager

    init(stores: StoresManager = ServiceLocator.stores,
         paymentReceiptEmailParameterDeterminer: ReceiptEmailParameterDeterminer) {
        self.stores = stores
        self.paymentReceiptEmailParameterDeterminer = paymentReceiptEmailParameterDeterminer
    }

    func collectPayment(for order: Order,
                        orderTotal: NSDecimalNumber,
                        paymentGatewayAccount: PaymentGatewayAccount,
                        paymentMethodTypes: [String],
                        stripeSmallestCurrencyUnitMultiplier: Decimal,
                        onWaitingForInput: @escaping () -> Void,
                        onProcessingMessage: @escaping () -> Void,
                        onDisplayMessage: @escaping (String) -> Void,
                        onProcessingCompletion: @escaping (PaymentIntent) -> Void,
                        onCompletion: @escaping (Result<CardPresentCapturedPaymentData, Error>) -> Void) {
        /// Set state of CardPresentPaymentStore
        ///
        let setAccount = CardPresentPaymentAction.use(paymentGatewayAccount: paymentGatewayAccount)

        stores.dispatch(setAccount)

        paymentParameters(
                order: order,
                orderTotal: orderTotal,
                country: paymentGatewayAccount.country,
                statementDescriptor: paymentGatewayAccount.statementDescriptor,
                paymentMethodTypes: paymentMethodTypes,
                stripeSmallestCurrencyUnitMultiplier: stripeSmallestCurrencyUnitMultiplier
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
                        case .cardRemovedAfterClientSidePaymentCapture:
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

    /// Retries capturing payment on the server side (on the merchant's site).
    /// - Parameters:
    ///   - order: the order to capture payment.
    ///   - paymentIntent: the payment intent after a successful payment capture on the client side.
    ///   - onCompletion: called when the server-side payment capture completes.
    func retryServerSidePaymentCapture(order: Order,
                                       paymentIntent: PaymentIntent,
                                       onCompletion: @escaping (Result<CardPresentCapturedPaymentData, Error>) -> Void) {
        let action = CardPresentPaymentAction.capturePaymentOnSite(siteID: order.siteID,
                                                                   orderID: order.orderID,
                                                                   paymentIntent: paymentIntent) { [weak self] publisher in
            guard let self = self else { return }

            var subscription: AnyCancellable?
            subscription = publisher
                .sink { completion in
                    subscription?.cancel()
                } receiveValue: { [weak self] result in
                    guard let self = self else { return }
                    switch result {
                    case .success:
                        self.completePaymentIntentCapture(order: order,
                                                          captureResult: .success(paymentIntent),
                                                          onCompletion: onCompletion)
                    case .failure(let error):
                        onCompletion(.failure(error))
                    }
                }
        }
        stores.dispatch(action)
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
                           orderTotal: NSDecimalNumber,
                           country: String,
                           statementDescriptor: String?,
                           paymentMethodTypes: [String],
                           stripeSmallestCurrencyUnitMultiplier: Decimal,
                           onCompletion: @escaping ((Result<PaymentParameters, Error>) -> Void)) {
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
                                               stripeSmallestCurrencyUnitMultiplier: stripeSmallestCurrencyUnitMultiplier,
                                               applicationFee: self.applicationFee(for: orderTotal, country: country),
                                               receiptDescription: self.receiptDescription(orderNumber: order.number),
                                               statementDescription: statementDescriptor,
                                               receiptEmail: receiptEmail,
                                               paymentMethodTypes: paymentMethodTypes,
                                               metadata: metadata)

            onCompletion(Result.success(parameters))
        }
    }

    private func applicationFee(for orderTotal: NSDecimalNumber, country: String) -> Decimal? {
        guard country.uppercased() == SiteAddress.CountryCode.CA.rawValue else {
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
        static let canadaFlatFee = NSDecimalNumber(string: "0.15")
        static let canadaPercentageFee = NSDecimalNumber(0)
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
