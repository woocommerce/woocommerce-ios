import Yosemite
/// Orchestrates the sequence of actions required to capture a payment:
/// 1. Check if there is a card reader connected
/// 2. Launch the reader discovering and pairing UI if there is no reader connected
/// 3. Obtain a Payment Intent from the card reader (i.e., create a payment intent, collect a payment method, and process the payment)
/// 4. Submit the Payment Intent to WCPay to capture a payment
/// Steps 1 and 2 will be implemented as part of https://github.com/woocommerce/woocommerce-ios/issues/4062
final class PaymentCaptureOrchestrator {
    private let currencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)

    func collectPayment(for order: Order,
                        onPresentMessage: @escaping (String) -> Void,
                        onClearMessage: @escaping () -> Void,
                        onProcessingMessage: @escaping () -> Void,
                        onCompletion: @escaping (Result<CardPresentReceiptParameters, Error>) -> Void) {

        // TODO. Check that there is a reader currently connected
        // otherwise launch the discovery+pairing UI
        // https://github.com/woocommerce/woocommerce-ios/issues/4062
        collectPaymentWithCardReader(for: order,
                                     onPresentMessage: onPresentMessage,
                                     onClearMessage: onClearMessage,
                                     onProcessingMessage: onProcessingMessage,
                                     onCompletion: onCompletion)
    }

    func printReceipt(for order: Order, params: CardPresentReceiptParameters) {
        let action = ReceiptAction.print(order: order, parameters: params)

        ServiceLocator.stores.dispatch(action)
    }

    func emailReceipt(for order: Order, params: CardPresentReceiptParameters, onContent: @escaping (String) -> Void) {
        let action = ReceiptAction.generateContent(order: order, parameters: params) { emailContent in
            onContent(emailContent)
        }

        ServiceLocator.stores.dispatch(action)
    }
}


private extension PaymentCaptureOrchestrator {
    func collectPaymentWithCardReader(for order: Order,
                                      onPresentMessage: @escaping (String) -> Void,
                                      onClearMessage: @escaping () -> Void,
                                      onProcessingMessage: @escaping () -> Void,
                                      onCompletion: @escaping (Result<CardPresentReceiptParameters, Error>) -> Void) {
        guard let orderTotal = currencyFormatter.convertToDecimal(from: order.total) else {
            DDLogError("Error: attempted to collect payment for an order without valid total.")
            onCompletion(.failure(CardReaderServiceError.paymentCapture()))
            return
        }

        let paymentParameters = PaymentParameters(amount: orderTotal as Decimal,
                                                  currency: order.currency,
                                                  receiptDescription: "Receipt description.",
                                                  statementDescription: "Statement description.",
                                                  receiptEmail: order.billingAddress?.email,
                                                  metadata: [CardPresentReceiptParameters.MetadataKeys.store:
                                                                ServiceLocator.stores.sessionManager.defaultSite?.name as Any])

        let action = CardPresentPaymentAction.collectPayment(siteID: order.siteID,
                                                             orderID: order.orderID, parameters: paymentParameters,
                                                             onCardReaderMessage: { (event) in
                                                                switch event {
                                                                case .displayMessage (let message):
                                                                    onPresentMessage(message)
                                                                case .waitingForInput (let message):
                                                                    onPresentMessage(message)
                                                                case .cardRemoved:
                                                                    onClearMessage()
                                                                default:
                                                                    break
                                                                }
                                                             }, onCompletion: { [weak self] result in
                                                                onProcessingMessage()
                                                                self?.completePaymentIntentCapture(order: order,
                                                                                                 captureResult: result,
                                                                                                 onCompletion: onCompletion)
        })

        ServiceLocator.stores.dispatch(action)
    }

    func completePaymentIntentCapture(order: Order,
                                    captureResult: Result<PaymentIntent, Error>,
                                    onCompletion: @escaping (Result<CardPresentReceiptParameters, Error>) -> Void) {
        switch captureResult {
        case .failure:
            let error = CardReaderServiceError.paymentCapture()
            onCompletion(.failure(error))
        case .success(let paymentIntent):
            submitPaymentIntent(siteID: order.siteID,
                                orderID: order.orderID,
                                paymentIntent: paymentIntent,
                                onCompletion: onCompletion)
        }
    }

    func submitPaymentIntent(siteID: Int64,
                             orderID: Int64,
                             paymentIntent: PaymentIntent,
                             onCompletion: @escaping (Result<CardPresentReceiptParameters, Error>) -> Void) {
        let action = WCPayAction.captureOrderPayment(siteID: siteID,
                                                     orderID: orderID,
                                                     paymentIntentID: paymentIntent.id) { result in

            guard let receiptParameters = paymentIntent.receiptParameters() else {
                let error = CardReaderServiceError.paymentCapture()

                DDLogError("⛔️ Payment completed without required metadata: \(error)")

                onCompletion(.failure(error))
                return
            }

            switch result {
            case .success:
                onCompletion(.success(receiptParameters))
            case .failure(let error):
                onCompletion(.failure(error))
                return
            }
        }

        ServiceLocator.stores.dispatch(action)
    }
}
