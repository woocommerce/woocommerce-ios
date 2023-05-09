import Foundation
import Codegen

/// Represents a FeeLine Entity within an Order.
///
public struct OrderFeeLine: Equatable, Codable, GeneratedFakeable, GeneratedCopiable {
    public let feeID: Int64

    /// Fee Name
    ///
    /// Sending a null value to the REST API removes the Fee Line from the Order.
    ///
    public let name: String?

    public let taxClass: String
    public let taxStatus: OrderFeeTaxStatus
    public let total: String
    public let totalTax: String
    public let taxes: [OrderItemTax]
    public let attributes: [OrderItemAttribute]

    /// OrderFeeLine struct initializer.
    ///
    public init(feeID: Int64,
                name: String?,
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

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let feeID = try container.decode(Int64.self, forKey: .feeID)
        let name = try container.decode(String.self, forKey: .name)
        let taxClass = try container.decode(String.self, forKey: .taxClass)
        let taxStatus = try container.decode(OrderFeeTaxStatus.self, forKey: .taxStatus)
        let total = try container.decode(String.self, forKey: .total)
        let totalTax = try container.decode(String.self, forKey: .totalTax)
        let taxes = try container.decode([OrderItemTax].self, forKey: .taxes)

        // Use failsafe decoding to discard any attributes with non-string values (currently not supported).
        let attributes = container.failsafeDecodeIfPresent(lossyList: [OrderItemAttribute].self, forKey: .attributes)

        self.init(feeID: feeID,
                  name: name,
                  taxClass: taxClass,
                  taxStatus: taxStatus,
                  total: total,
                  totalTax: totalTax,
                  taxes: taxes,
                  attributes: attributes)
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
