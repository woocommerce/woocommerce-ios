/// Order Payment methods
enum OrderPaymentMethod: RawRepresentable {
    /// Cash on Delivery
    case cod

    /// No payment method assigned.
    case none

    /// Other
    case unknown

    /// Designated Initializer.
    ///
    public init(rawValue: String) {
        switch rawValue {
        case Keys.cod:
            self = .cod
        case Keys.none:
            self = .none
        default:
            self = .unknown
        }
    }

    public var rawValue: String {
        switch self {
        case .cod:
            return Keys.cod
        case .none:
            return Keys.none
        default:
            return Keys.unknown
        }
    }
}


private enum Keys {
    static let cod = "cod"
    static let none = ""
    static let unknown = "unknown"
}
