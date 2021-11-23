import Foundation
import Codegen

/// Represents a FeeLine Entity within an Order.
///
public struct OrderFeeLine: Equatable, Codable, GeneratedFakeable {
    public let feeID: Int64
    public let name: String
    public let taxClass: String
    public let taxStatus: OrderFeeTaxStatus
    public let total: String
    public let totalTax: String
    public let taxes: [OrderItemTax]
    public let attributes: [OrderItemAttribute]

    /// OrderFeeLine struct initializer.
    ///
    public init(feeID: Int64,
                name: String,
                taxClass: String,
                taxStatus: OrderFeeTaxStatus,
                total: String,
                totalTax: String,
                taxes: [OrderItemTax],
                attributes: [OrderItemAttribute]) {
        self.feeID = feeID
        self.name = name
        self.taxClass = taxClass
        self.taxStatus = taxStatus
        self.total = total
        self.totalTax = totalTax
        self.taxes = taxes
        self.attributes = attributes
    }
}

// MARK: Codable
extension OrderFeeLine {
    /// Encodes OrderFeeLine writable fields.
    ///
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(feeID, forKey: .feeID)
        try container.encode(name, forKey: .name)
        try container.encode(taxClass, forKey: .taxClass)
        try container.encode(taxStatus, forKey: .taxStatus)
        try container.encode(total, forKey: .total)
    }
}

/// Defines all of the OrderFeeLine's CodingKeys.
///
private extension OrderFeeLine {

    enum CodingKeys: String, CodingKey {
        case feeID      = "id"
        case name       = "name"
        case taxClass   = "tax_class"
        case taxStatus  = "tax_status"
        case total      = "total"
        case totalTax   = "total_tax"
        case taxes      = "taxes"
        case attributes = "meta_data"
    }
}
