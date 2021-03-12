import Foundation


/// Represents a Tax Refund for a specific Order Item.
///
public struct OrderItemTaxRefund: Codable, GeneratedFakeable {

    /// Tax ID for line item
    ///
    public let taxID: Int64

    /// Tax subtotal
    ///
    public let subtotal: String

    /// Product tax amount
    ///
    public let total: String

    /// OrderItemTaxRefund struct initializer
    ///
    public init(taxID: Int64, subtotal: String, total: String) {
        self.taxID = taxID
        self.subtotal = subtotal
        self.total = total
    }

    /// The public initializer for OrderItemTaxRefund
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let taxID = try container.decode(Int64.self, forKey: .taxID)
        let subtotal = try container.decode(String.self, forKey: .subtotal)
        let total = try container.decode(String.self, forKey: .total)

        // initialize the struct
        self.init(taxID: taxID, subtotal: subtotal, total: total)
    }

    /// The public encoder for OrderItemTaxRefund
    ///
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(taxID, forKey: .taxID)
        try container.encode(total, forKey: .total)
    }
}


/// Defines all of the OrderItemRefund CodingKeys.
///
private extension OrderItemTaxRefund {

    enum CodingKeys: String, CodingKey {
        case taxID      = "id"
        case subtotal
        case total
    }
}


// MARK: - Comparable Conformance
//
extension OrderItemTaxRefund: Comparable {
    public static func == (lhs: OrderItemTaxRefund, rhs: OrderItemTaxRefund) -> Bool {
        return lhs.taxID == rhs.taxID &&
            lhs.subtotal == rhs.subtotal &&
            lhs.total == rhs.total
    }

    public static func < (lhs: OrderItemTaxRefund, rhs: OrderItemTaxRefund) -> Bool {
        return lhs.taxID < rhs.taxID ||
            (lhs.taxID == rhs.taxID && lhs.subtotal < rhs.subtotal) ||
            (lhs.taxID == rhs.taxID && lhs.subtotal == rhs.subtotal && lhs.total < rhs.total)
    }
}
