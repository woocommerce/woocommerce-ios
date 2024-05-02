import Foundation

/// Represents a Shipping Method Entity.
///
public struct ShippingMethod: Codable, Equatable {
    /// Shipping Method ID
    ///
    public let id: String

    /// Shipping Method Title
    ///
    public let title: String
}
