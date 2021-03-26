/// A property wrapper to return a string as lowercased.
/// If there is a way to enforce that the content of the string is
/// a valid ISO three-letter currency code, this would be a good place to add it
/// We do this to add an extra layer of validation to the values that we
/// pass to the Stripe Terminal SDK when creating a payment intent:
/// https://stripe.dev/stripe-terminal-ios/docs/Classes/SCPPaymentIntentParameters.html#/c:objc(cs)SCPPaymentIntentParameters(py)currency
@propertyWrapper
public struct CurrencyCode {
    private(set) var value: String

    public init(wrappedValue value: String) {
        self.value = value
    }

    public var wrappedValue: String {
        get {
            return value.lowercased()
        }
        set {
            value = newValue
        }
    }
}
