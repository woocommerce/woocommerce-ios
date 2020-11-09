import Foundation

/// Represents a Payment Gateway.
///
public struct PaymentGateway: Decodable {

    /// Features for payment gateway.
    ///
    public enum Features {
        case products
        case refunds
        case custom(raw: String)
    }

    /// Site identifier.
    ///
    public let siteID: Int64

    /// Gateway Identifier.
    ///
    public let gatewayID: String

    /// Title for the payment gateway.
    ///
    public let title: String

    /// Description of the payment gateway.
    ///
    public let description: String

    /// Wether the payment gateway is enabled on the site or not.
    ///
    public let enabled: Bool

    /// List of features the payment gateway supports.
    ///
    public let features: [Features]
}

// MARK: Features Decodable
extension PaymentGateway.Features: RawRepresentable, Decodable {

    /// Enum containing the 'Known' Features Keys
    ///
    private enum Keys {
        static let products = "products"
        static let refunds = "refunds"
    }

    public init?(rawValue: String) {
        switch rawValue {
        case Keys.products:
            self = .products
        case Keys.refunds:
            self = .refunds
        default:
            self = .custom(raw: rawValue)
        }
    }

    public var rawValue: String {
        switch self {
        case .products:
            return Keys.products
        case .refunds:
            return Keys.refunds
        case .custom(let raw):
            return raw
        }
    }
}
