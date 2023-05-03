import Foundation
import Codegen

/// Represents a TaxLine Entity within an Order.
///
public struct OrderTaxLine: Decodable, Equatable, GeneratedFakeable, GeneratedCopiable {
    public let taxID: Int64
    public let rateCode: String
    public let rateID: Int64
    public let label: String
    public let isCompoundTaxRate: Bool
    public let totalTax: String
    public let totalShippingTax: String
    public let ratePercent: Double
    public let attributes: [OrderItemAttribute]

    /// OrderTaxLine struct initializer.
    ///
    public init(taxID: Int64,
                rateCode: String,
                rateID: Int64,
                label: String,
                isCompoundTaxRate: Bool,
                totalTax: String,
                totalShippingTax: String,
                ratePercent: Double,
                attributes: [OrderItemAttribute]) {
        self.taxID = taxID
        self.rateCode = rateCode
        self.rateID = rateID
        self.label = label
        self.isCompoundTaxRate = isCompoundTaxRate
        self.totalTax = totalTax
        self.totalShippingTax = totalShippingTax
        self.ratePercent = ratePercent
        self.attributes = attributes
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let taxID = try container.decode(Int64.self, forKey: .taxID)
        let rateCode = try container.decode(String.self, forKey: .rateCode)
        let rateID = try container.decode(Int64.self, forKey: .rateID)
        let label = try container.decode(String.self, forKey: .label)
        let isCompoundTaxRate = try container.decode(Bool.self, forKey: .isCompoundTaxRate)
        let totalTax = try container.decode(String.self, forKey: .totalTax)
        let totalShippingTax = try container.decode(String.self, forKey: .totalShippingTax)
        let ratePercent = try container.decode(Double.self, forKey: .ratePercent)

        // Use failsafe decoding to discard any attributes with non-string values (currently not supported).
        let attributes = container.failsafeDecodeIfPresent(lossyList: [OrderItemAttribute].self, forKey: .attributes)

        self.init(taxID: taxID,
                  rateCode: rateCode,
                  rateID: rateID,
                  label: label,
                  isCompoundTaxRate: isCompoundTaxRate,
                  totalTax: totalTax,
                  totalShippingTax: totalShippingTax,
                  ratePercent: ratePercent,
                  attributes: attributes)
    }
}

/// Defines all of the OrderTaxLine's CodingKeys.
///
private extension OrderTaxLine {

    enum CodingKeys: String, CodingKey {
        case taxID             = "id"
        case rateCode          = "rate_code"
        case rateID            = "rate_id"
        case label
        case isCompoundTaxRate = "compound"
        case totalTax          = "tax_total"
        case totalShippingTax  = "shipping_tax_total"
        case ratePercent       = "rate_percent"
        case attributes        = "meta_data"
    }
}
