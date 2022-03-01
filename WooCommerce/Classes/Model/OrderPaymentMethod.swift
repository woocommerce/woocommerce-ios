/// Order Payment methods
enum OrderPaymentMethod: RawRepresentable {
    /// Cash on Delivery
    case cod

    /// WooCommerce Payments
    case woocommercePayments

    /// Bookings
    case bookings

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
        case Keys.woocommercePayments:
            self = .woocommercePayments
        case Keys.bookings:
            self = .bookings
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
        case .woocommercePayments:
            return Keys.woocommercePayments
        case .bookings:
            return Keys.bookings
        case .none:
            return Keys.none
        default:
            return Keys.unknown
        }
    }
}


private enum Keys {
    static let cod = "cod"
    static let woocommercePayments = "woocommerce_payments"
    static let bookings = "wc-booking-gateway"
    static let none = ""
    static let unknown = "unknown"
}
