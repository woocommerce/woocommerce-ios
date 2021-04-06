/// A property wrapper to validate that a property is a valid email
/// Property Wrappers can not throw, so
/// what this wrapper does is return a nil when trying to set an invalid
/// email address as a value of a property of type String.
/// The reason to do this is add an extra layer of validation before passing
/// an instance of PaymentIntentParameters to the Stripe Terminal SDK
/// https://emailregex.com

@propertyWrapper
public struct Email<Value: StringProtocol> {
    var value: Value?

    public init(wrappedValue value: Value?) {
        self.value = value
    }

    public var wrappedValue: Value? {
        get {
            return validate(email: value) ? value : nil
        }
        set {
            value = newValue
        }
    }
    private func validate(email: Value?) -> Bool {
        guard let email = email else { return false }
        // https://emailregex.com
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
}
