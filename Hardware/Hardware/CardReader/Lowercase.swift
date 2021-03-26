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
