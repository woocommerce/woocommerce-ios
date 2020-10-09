import Foundation


/// Represents the Taxes for a specific Order Item.
///
public struct OrderItemTax: Codable, Hashable {

    /// Tax ID for line item
    ///
    public let taxID: Int64

    /// Tax subtotal
    ///
    public let subtotal: String

    /// Product tax amount
    ///
    public let total: String

    /// OrderItemTax struct initializer
    ///
    public init(taxID: Int64, subtotal: String, total: String) {
        self.taxID = taxID
        self.subtotal = subtotal
        self.total = total
    }

    /// The public initializer for OrderItemTax
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let taxID = try container.decode(Int64.self, forKey: .taxID)
        let subtotal = try container.decode(String.self, forKey: .subtotal)
        let total = try container.decode(String.self, forKey: .total)

        // initialize the struct
        self.init(taxID: taxID, subtotal: subtotal, total: total)
    }

    /// The public encoder for OrderItemTax
    ///
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(taxID, forKey: .taxID)
        try container.encode(subtotal, forKey: .subtotal)
        try container.encode(total, forKey: .total)
    }
}


/// Defines all of the OrderItemTax CodingKeys.
///
private extension OrderItemTax {

    enum CodingKeys: String, CodingKey {
        case taxID      = "id"
        case subtotal
        case total
    }
}


// MARK: - Comparable Conformance
//
extension OrderItemTax: Comparable {
    public static func == (lhs: OrderItemTax, rhs: OrderItemTax) -> Bool {
        return lhs.taxID == rhs.taxID &&
            lhs.subtotal == rhs.subtotal &&
            lhs.total == rhs.total
    }

    public static func < (lhs: OrderItemTax, rhs: OrderItemTax) -> Bool {
        return lhs.taxID < rhs.taxID ||
            (lhs.taxID == rhs.taxID && lhs.subtotal < rhs.subtotal) ||
            (lhs.taxID == rhs.taxID && lhs.subtotal == rhs.subtotal && lhs.total < rhs.total)
    }
}
