/// A property wrapper to return a string where:
/// - The characters <>"' are replaced.
/// - The maximum length of the string is 22 characters
/// We do this to add an extra layer of validation to the values that we
/// pass to the Stripe Terminal SDK when creating a payment intent:
/// https://stripe.dev/stripe-terminal-ios/docs/Classes/SCPPaymentIntentParameters.html#/c:objc(cs)SCPPaymentIntentParameters(py)statementDescriptor
/// If we pass strings longer than 22 characters or that contain any of the
/// characters that are not allowed, the Stripe Terminal SDK will crash.
@propertyWrapper
public struct StatementDescriptor {

    private(set) var value: String?

    public init(wrappedValue value: String?) {
        self.value = value
    }

    public var wrappedValue: String? {
        get {
            guard let value = value else {
                return nil
            }

            return String(value.components(separatedBy: Constants.charactersToReplace)
                .joined(separator: Constants.replacement)
                            .prefix(Constants.maxLength))
        }
        set {
            value = newValue
        }
    }
}

private extension StatementDescriptor {
    enum Constants {
        static let charactersToReplace = CharacterSet(["<", ">", "'", "\""])
        static let replacement = "-"
        static let maxLength = 22
    }
}
