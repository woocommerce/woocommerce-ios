import Foundation

/// Represents the taxes for a specific shipping item.
///
public struct ShippingLineTax: Decodable, Hashable {

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
