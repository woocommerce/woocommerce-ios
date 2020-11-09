import Foundation

/// Represents a Payment Gateway.
///
public struct PaymentGateway {

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
