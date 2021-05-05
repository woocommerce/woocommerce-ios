import Yosemite
/// Orchestrates the sequence of actions required to capture a payment:
/// 1. Check the there is a card reader connected
/// 2. Launch the reader discovering and pairing UI if there is no reader connected
/// 3. Obtain a Payment Intent from the card reader
/// 4. Submit the Payment Intent to WCPay
/// Steps 1 and 2 will be implemented as part of https://github.com/woocommerce/woocommerce-ios/issues/4062
final class PaymentCaptureOrchestrator {
    private let currencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)

    func collectPayment(for order: Order,
                        onPresentMessage: @escaping (String) -> Void,
                        onClearMessage: @escaping () -> Void,
                        onCompletion: @escaping (Result<CardPresentReceiptParameters, Error>) -> Void) {

        // TODO. Check that there i a reader currently connected
        // otherwise launch the discovery+pairing UI
        // https://github.com/woocommerce/woocommerce-ios/issues/4062
        collectPaymentWithCardReader(for: order,
                                     onPresentMessage: onPresentMessage,
                                     onClearMessage: onClearMessage,
                                     onCompletion: onCompletion)
    }

    func printReceipt(params: CardPresentReceiptParameters) {

    }

    func emailReceipt(params: CardPresentReceiptParameters) {
        // TO BE IMPLEMENTED
        // https://github.com/woocommerce/woocommerce-ios/issues/4014
    }
}


private extension PaymentCaptureOrchestrator {
    func collectPaymentWithCardReader(for order: Order,
                                      onPresentMessage: @escaping (String) -> Void,
                                      onClearMessage: @escaping () -> Void,
                                      onCompletion: @escaping (Result<CardPresentReceiptParameters, Error>) -> Void) {
        guard let orderTotal = currencyFormatter.convertToDecimal(from: order.total) else {
            DDLogError("Error: attempted to collect payment for an order without valid total. ")
            onCompletion(.failure(CardReaderServiceError.paymentCapture()))
            return
        }

        let paymentParameters = PaymentParameters(amount: orderTotal as Decimal,
                                                  currency: order.currency,
                                                  receiptDescription: "Receipt description.",
                                                  statementDescription: "Statement description.",
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
                                                                self?.submitPaymentIntentToWCPay(order: order,
                                                                                                 captureResult: result,
                                                                                                 onCompletion: onCompletion)
        })

        ServiceLocator.stores.dispatch(action)
    }

    func submitPaymentIntentToWCPay(order: Order,
                                    captureResult: Result<CardPresentReceiptParameters, Error>,
                                    onCompletion: @escaping (Result<CardPresentReceiptParameters, Error>) -> Void) {
        onCompletion(captureResult)
        //let action = WCPayAction.captureOrderPayment(siteID: <#T##Int64#>, orderID: <#T##Int64#>, paymentIntentID: <#T##String#>, completion: <#T##(Result<Void, Error>) -> Void#>)
    }
}
