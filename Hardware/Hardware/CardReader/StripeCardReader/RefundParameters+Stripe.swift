#if !targetEnvironment(macCatalyst)
import StripeTerminal

extension Hardware.RefundParameters {
    /// Initializes a StripeTerminal.RefundParameters from a
    /// Hardware.RefundParameters
    func toStripe() -> StripeTerminal.RefundParameters? {
        // Shortcircuit if we do not have a valid currency code
        guard !currency.isEmpty else {
            return nil
        }

        /// The amount of the refund needs to be provided in the currency’s smallest unit.
        /// https://stripe.dev/stripe-terminal-ios/docs/Classes/SCPRefundParameters.html#/c:objc(cs)SCPRefundParameters(py)amount
        let amountInSmallestUnit = amount * 100

        let amountForStripe = NSDecimalNumber(decimal: amountInSmallestUnit).uintValue

        let returnValue = StripeTerminal.RefundParameters(chargeId: chargeId, amount: amountForStripe, currency: currency)

        return returnValue
    }
}
#endif
