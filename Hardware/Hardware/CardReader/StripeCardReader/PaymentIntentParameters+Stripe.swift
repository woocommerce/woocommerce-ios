#if !targetEnvironment(macCatalyst)
import StripeTerminal

extension Hardware.PaymentIntentParameters {
    /// Initializes a StripeTerminal.PaymentIntentParameters from a
    /// Hardware.PaymentIntentParameters
    func toStripe() -> StripeTerminal.PaymentIntentParameters? {
        // Shortcircuit if we do not have a valid currency code
        guard !currency.isEmpty else {
            return nil
        }

        // Shortcircuit if we do not have a valid payment method
        guard !paymentMethodTypes.isEmpty else {
            return nil
        }

        let amountForStripe = prepareAmountForStripe(amount)

        let returnValue = StripeTerminal.PaymentIntentParameters(amount: amountForStripe, currency: currency, paymentMethodTypes: paymentMethodTypes)
        returnValue.stripeDescription = receiptDescription

        if let applicationFee = applicationFee {
            /// Stripe requires that "The amount must be provided as a boxed UInt in the currency's smallest unit."
            /// Smallest-unit and UInt conversion is done in the same way as for the total amount, but that does not need to be boxed.
            let applicationFeeForStripe = NSNumber(value: prepareAmountForStripe(applicationFee))

            returnValue.applicationFeeAmount = applicationFeeForStripe
        }

        /// Stripe allows the credit card statement descriptor to be nil, but not an empty string
        /// https://stripe.dev/stripe-terminal-ios/docs/Classes/SCPPaymentIntentParameters.html#/c:objc(cs)SCPPaymentIntentParameters(py)statementDescriptor
        returnValue.statementDescriptor = nil
        let descriptor = statementDescription ?? ""
        if !descriptor.isEmpty {
            returnValue.statementDescriptor = descriptor
        }

        returnValue.receiptEmail = receiptEmail
        returnValue.metadata = metadata

        return returnValue
    }
}

private extension Hardware.PaymentIntentParameters {
    enum Constants {
        static let smallestCurrencyUnitMultiplier: Decimal = 100
    }

    func prepareAmountForStripe(_ amount: Decimal) -> UInt {
        /// The amount of the payment needs to be provided in the currency’s smallest unit.
        /// https://stripe.dev/stripe-terminal-ios/docs/Classes/SCPPaymentIntentParameters.html#/c:objc(cs)SCPPaymentIntentParameters(py)amount
        let amountInSmallestUnit = amount * Constants.smallestCurrencyUnitMultiplier
        return NSDecimalNumber(decimal: amountInSmallestUnit).uintValue
    }
}
#endif
