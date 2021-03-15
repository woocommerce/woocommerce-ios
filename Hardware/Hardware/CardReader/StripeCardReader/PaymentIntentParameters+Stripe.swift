import StripeTerminal

extension Hardware.PaymentIntentParameters {
    /// Initializes a StripeTerminal.PaymentIntentParameters from a
    /// Hardware.PaymentIntentParameters
    func toStripe() -> StripeTerminal.PaymentIntentParameters {
        let returnValue = StripeTerminal.PaymentIntentParameters(amount: self.amount, currency: self.currency)
        returnValue.stripeDescription = self.receiptDescription
        returnValue.statementDescriptor = self.statementDescription

        return returnValue
    }
}
