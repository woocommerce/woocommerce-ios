import Foundation

/// A property wrapper that sanitizes statement descriptors before passing them to Stripe Terminal.
/// Valid descriptors contain 5 to 22 ASCII characters, at least one letter, and none of Stripe's
/// forbidden characters. Invalid descriptors are returned as `nil` so Stripe can use the account default.
/// https://docs.stripe.com/get-started/account/statement-descriptors#requirements
@propertyWrapper
public struct StatementDescriptor {

    private(set) var value: String?

    public init(wrappedValue value: String?) {
        self.value = value
    }

    public var wrappedValue: String? {
        get {
            guard let value else {
                return nil
            }

            return Self.sanitize(value)
        }
        set {
            value = newValue
        }
    }
}

private extension StatementDescriptor {
    static func sanitize(_ value: String) -> String? {
        let truncatedValue = String(value.components(separatedBy: Constants.charactersToReplace)
            .joined(separator: Constants.replacement)
            .prefix(Constants.maxLength))

        guard truncatedValue.count >= Constants.minLength,
              truncatedValue.contains(where: \.isASCIILetter) else {
            return nil
        }

        return truncatedValue
    }

    enum Constants {
        static let charactersToReplace = CharacterSet(["<", ">", "'", "\"", "*"])
        static let replacement = "-"
        static let minLength = 5
        static let maxLength = 22
    }
}

private extension Character {
    var isASCIILetter: Bool {
        guard unicodeScalars.count == 1,
              let value = unicodeScalars.first?.value else {
            return false
        }
        return (65...90).contains(value) || (97...122).contains(value)
    }
}
