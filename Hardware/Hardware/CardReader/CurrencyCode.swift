/// A property wrapper to return a string as lowercased.
/// This checks also that the currency code is one of the codes
/// returned by Locale.isoCurrencyCodes. If it isn't, it will return an empty string
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
            guard Locale.isoCurrencyCodes.map({ $0.uppercased() }).contains(value.uppercased()) else {
                return ""
            }

            return value.lowercased()
        }
        set {
            value = newValue
        }
    }
}
