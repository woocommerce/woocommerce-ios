/// Order Payment methods
enum OrderPaymentMethod: RawRepresentable {
    /// Cash on Delivery
    case cod
    /// Other
    case unknown

    /// Designated Initializer.
    ///
    public init(rawValue: String) {
        switch rawValue {
        case Keys.cod:
            self = .cod
        default:
            self = .unknown
        }
    }

    public var rawValue: String {
        switch self {
        case .cod:
            return Keys.cod
        default:
            return Keys.unknown
        }
    }
}


private enum Keys {
    static let cod = "cod"
    static let unknown = "unknown"
}
