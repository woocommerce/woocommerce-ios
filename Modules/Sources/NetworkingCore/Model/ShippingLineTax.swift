import Foundation
import Codegen

/// Represents the taxes for a specific shipping item.
///
public struct ShippingLineTax: Decodable, Hashable, Sendable, GeneratedFakeable {

    /// Tax ID for shipping item
    ///
    public let taxID: Int64

    /// Tax subtotal
    ///
    public let subtotal: String

    /// Shipping tax amount
    ///
    public let total: String

    /// OrderItemTax struct initializer
    ///
    public init(taxID: Int64, subtotal: String, total: String) {
        self.taxID = taxID
        self.subtotal = subtotal
        self.total = total
    }

    /// The public initializer for ShippingLineTax.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let taxID = container.failsafeDecodeInt64(forKey: .taxID)
        let subtotal = try container.decode(String.self, forKey: .subtotal)
        let total = try container.decode(String.self, forKey: .total)

        self.init(taxID: taxID, subtotal: subtotal, total: total)
    }
}

/// Defines all of the ShippingLineTax CodingKeys.
///
private extension ShippingLineTax {
    enum CodingKeys: String, CodingKey {
        case taxID = "id"
        case subtotal
        case total
    }
}
