import StripeTerminal

extension Hardware.PaymentIntentParameters {
    /// Initializes a StripeTerminal.PaymentIntentParameters from a
    /// Hardware.PaymentIntentParameters
    func toStripe() -> StripeTerminal.PaymentIntentParameters? {
        // Shortcircuit if we do not have a valid currency code
        guard !self.currency.isEmpty else {
            return nil
        }

        let returnValue = StripeTerminal.PaymentIntentParameters(amount: self.amount, currency: self.currency)
        returnValue.stripeDescription = self.receiptDescription
        returnValue.statementDescriptor = self.statementDescription
        returnValue.receiptEmail = self.receiptEmail
        returnValue.metadata = self.metadata

        return returnValue
    }
}
