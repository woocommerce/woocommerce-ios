import StripeTerminal

extension PaymentMethodDetails {
    init?(details: SCPPaymentMethodDetails?) {
        guard let details = details else {
            return nil
        }
        self.type = PaymentMethodType(methodType: details.type)
        self.cardPresent = CardPresentDetails(cardPresentDetails: details.cardPresent)
    }
}
