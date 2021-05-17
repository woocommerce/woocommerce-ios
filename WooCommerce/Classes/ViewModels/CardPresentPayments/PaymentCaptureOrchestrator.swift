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
                        paymentsAccount: WCPayAccount?,
                        onPresentMessage: @escaping (String) -> Void,
                        onClearMessage: @escaping () -> Void,
                        onProcessingMessage: @escaping () -> Void,
                        onCompletion: @escaping (Result<CardPresentReceiptParameters, Error>) -> Void) {
        guard let parameters = paymentParameters(order: order, account: paymentsAccount) else {
            DDLogError("Error: failed to create payment parameters for an order")
            onCompletion(.failure(CardReaderServiceError.paymentCapture()))
            return
        }
        let action = CardPresentPaymentAction.collectPayment(siteID: order.siteID,
                                                             orderID: order.orderID, parameters: parameters,
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

    func saveReceipt(for order: Order, params: CardPresentReceiptParameters) {
        let action = ReceiptAction.saveReceipt(order: order, parameters: params)

        ServiceLocator.stores.dispatch(action)
    }
}


private extension PaymentCaptureOrchestrator {
    func completePaymentIntentCapture(order: Order,
                                    captureResult: Result<PaymentIntent, Error>,
                                    onCompletion: @escaping (Result<CardPresentReceiptParameters, Error>) -> Void) {
        switch captureResult {
        case .failure:
            let error = CardReaderServiceError.paymentCapture()
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
        let action = WCPayAction.captureOrderPayment(siteID: siteID,
                                                     orderID: order.orderID,
                                                     paymentIntentID: paymentIntent.id) { [weak self] result in

            guard let receiptParameters = paymentIntent.receiptParameters() else {
                let error = CardReaderServiceError.paymentCapture()

                DDLogError("⛔️ Payment completed without required metadata: \(error)")

                onCompletion(.failure(error))
                return
            }

            switch result {
            case .success:
                self?.saveReceipt(for: order, params: receiptParameters)
                onCompletion(.success(receiptParameters))
            case .failure(let error):
                onCompletion(.failure(error))
                return
            }
        }

        ServiceLocator.stores.dispatch(action)
    }

    func paymentParameters(order: Order, account: WCPayAccount?) -> PaymentParameters? {
        guard let orderTotal = currencyFormatter.convertToDecimal(from: order.total) else {
            DDLogError("Error: attempted to collect payment for an order without a valid total.")
            return nil
        }

        return PaymentParameters(amount: orderTotal as Decimal,
                                                  currency: order.currency,
                                                  receiptDescription: receiptDescription(),
                                                  statementDescription: account?.statementDescriptor,
                                                  receiptEmail: order.billingAddress?.email,
                                                  metadata: [CardPresentReceiptParameters.MetadataKeys.store:
                                                                ServiceLocator.stores.sessionManager.defaultSite?.name as Any])
    }

    func receiptDescription() -> String? {
        guard let storeName = ServiceLocator.stores.sessionManager.defaultSite?.name else {
            return nil
        }

        return String.localizedStringWithFormat(Localization.receiptDescription,
                                                storeName)
    }
}

private extension PaymentCaptureOrchestrator {
    enum Localization {
        static let receiptDescription = NSLocalizedString("Receipt from %1$@",
                                                             comment: "Message included in emailed receipts."
                                                                + "Reads as: Receipt from @{store name}"
                                                                + "Parameters: %1$@ - store name")
    }
}
