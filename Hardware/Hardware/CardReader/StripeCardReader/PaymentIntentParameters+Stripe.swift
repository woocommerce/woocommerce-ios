import StripeTerminal

extension Hardware.PaymentIntentParameters {
    /// Initializes a StripeTerminal.PaymentIntentParameters from a
    /// Hardware.PaymentIntentParameters
    func toStripe() -> StripeTerminal.PaymentIntentParameters? {
        // Shortcircuit if we do not have a valid currency code
        guard !currency.isEmpty else {
            return nil
        }

        /// The amount of the payment needs to be provided in the currency’s smallest unit.
        /// https://stripe.dev/stripe-terminal-ios/docs/Classes/SCPPaymentIntentParameters.html#/c:objc(cs)SCPPaymentIntentParameters(py)amount
        let amountInSmallestUnit = amount * 100

        let amountForStripe = NSDecimalNumber(decimal: amountInSmallestUnit).uintValue

        let returnValue = StripeTerminal.PaymentIntentParameters(amount: amountForStripe, currency: currency)
        returnValue.stripeDescription = receiptDescription
        returnValue.statementDescriptor = nonEmptyStatementDescription
        returnValue.receiptEmail = receiptEmail
        returnValue.customer = customerID
        returnValue.metadata = metadata

        return returnValue
    }

    /// Stripe allows the credit card statement descriptor to be nil, but not an empty string
    ///
    /// https://stripe.dev/stripe-terminal-ios/docs/Classes/SCPPaymentIntentParameters.html#/c:objc(cs)SCPPaymentIntentParameters(py)statementDescriptor
    private var nonEmptyStatementDescription: String? {
        return statementDescription.flatMap {
            return $0.isEmpty ? nil : $0
        }
    }
}
