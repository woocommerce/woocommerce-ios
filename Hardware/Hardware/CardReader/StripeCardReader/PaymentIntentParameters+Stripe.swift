import StripeTerminal

extension Hardware.PaymentIntentParameters {
    /// Initializes a StripeTerminal.PaymentIntentParameters from a
    /// Hardware.PaymentIntentParameters
    func toStripe() -> StripeTerminal.PaymentIntentParameters? {
        // Shortcircuit if we do not have a valid currency code
        guard !self.currency.isEmpty else {
            return nil
        }

        /// The amount of the payment needs to be provided in the currency’s smallest unit.
        ///https://stripe.dev/stripe-terminal-ios/docs/Classes/SCPPaymentIntentParameters.html#/c:objc(cs)SCPPaymentIntentParameters(py)amount
        let amountInSmallestUnit = self.amount.multiplying(byPowerOf10: 2)

        let returnValue = StripeTerminal.PaymentIntentParameters(amount: UInt(truncating: amountInSmallestUnit), currency: self.currency)
        returnValue.stripeDescription = self.receiptDescription
        returnValue.statementDescriptor = self.statementDescription
        returnValue.receiptEmail = self.receiptEmail
        returnValue.metadata = self.metadata

        return returnValue
    }
}
