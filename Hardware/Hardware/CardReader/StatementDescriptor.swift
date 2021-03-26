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
