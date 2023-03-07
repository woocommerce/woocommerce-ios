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
