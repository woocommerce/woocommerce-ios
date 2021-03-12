import StripeTerminal

extension Hardware.PaymentIntentParameters {
//    /// Convenience initializer
//    /// - Parameter intentParameters: An instance of a StripeTerminal.PaymentIntentParameters
//    init(intentParameters: StripePaymentIntentParameters) {
//        self.amount = intentParameters.amount
//        self.currency = intentParameters.currency
//        self.receiptDescription = intentParameters.stripeDescription
//        self.statementDescription = intentParameters.statementDescriptor
//    }
//
    func toStripe() -> StripeTerminal.PaymentIntentParameters {
        let returnValue = StripeTerminal.PaymentIntentParameters(amount: self.amount, currency: self.currency)
        returnValue.stripeDescription = self.receiptDescription
        returnValue.statementDescriptor = self.statementDescription

        return returnValue
    }
}


//protocol StripePaymentIntentParameters {
//    var amount: UInt { get }
//    var currency: String { get }
//    var stripeDescription: String { get set }
//    var statementDescriptor: String { get set }
//}
//
//extension StripeTerminal.PaymentIntentParameters: StripePaymentIntentParameters {}
