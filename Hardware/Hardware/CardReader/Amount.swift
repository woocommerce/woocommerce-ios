@propertyWrapper
public struct Amount {
    private(set) var value: UInt

    public init(wrappedValue value: UInt) {
        self.value = value
    }

    public var wrappedValue: UInt {
        get {
            value * 100
        }
        set {
            value = newValue
        }
    }
}

