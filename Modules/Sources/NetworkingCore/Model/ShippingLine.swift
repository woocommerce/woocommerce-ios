import Foundation
import Codegen

/// Represents a Shipping Line Entity.
///
public struct ShippingLine: Codable, Equatable, Sendable, GeneratedFakeable, GeneratedCopiable {
    public let shippingID: Int64
    public let methodTitle: String

    /// Shipping Method ID
    ///
    /// Sending a null value to the REST API removes the Shipping Line.
    ///
    public let methodID: String?

    public let total: String
    public let totalTax: String
    public let taxes: [ShippingLineTax]

    /// Original order line ID when this shipping line belongs to a refund.
    public let refundedItemID: Int64?

    /// Shipping Method struct initializer.
    ///
    public init(shippingID: Int64,
                methodTitle: String,
                methodID: String?,
                total: String,
                totalTax: String,
                taxes: [ShippingLineTax],
                refundedItemID: Int64? = nil) {

        self.shippingID = shippingID
        self.refundedItemID = refundedItemID
        self.methodTitle = methodTitle
        self.methodID = methodID
        self.total = total
        self.totalTax = totalTax
        self.taxes = taxes
    }
}

// MARK: Codable
extension ShippingLine {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let metadata = try? container.decode([MetaData].self, forKey: .metadata)
        let originalID: Int64?
        if let raw = metadata?.first(where: { $0.key == "_refunded_item_id" })?.value.stringValue {
            originalID = Int64(raw)
        } else {
            originalID = nil
        }
        self.init(shippingID: try container.decode(Int64.self, forKey: .shippingID),
                  methodTitle: try container.decode(String.self, forKey: .methodTitle),
                  methodID: try container.decodeIfPresent(String.self, forKey: .methodID),
                  total: try container.decode(String.self, forKey: .total),
                  totalTax: try container.decode(String.self, forKey: .totalTax),
                  taxes: try container.decode([ShippingLineTax].self, forKey: .taxes),
                  refundedItemID: originalID)
    }

    /// Encodes ShippingLine writable fields.
    ///
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(shippingID, forKey: .shippingID)
        try container.encode(methodTitle, forKey: .methodTitle)
        try container.encode(methodID, forKey: .methodID)
        try container.encode(total, forKey: .total)
    }
}


/// Defines all of the Shipping Line CodingKeys
///
private extension ShippingLine {

    enum CodingKeys: String, CodingKey {
        case metadata              = "meta_data"
        case shippingID            = "id"
        case methodTitle           = "method_title"
        case methodID              = "method_id"
        case total                 = "total"
        case totalTax              = "total_tax"
        case taxes                 = "taxes"
    }
}


// MARK: - Comparable Conformance
//
extension ShippingLine: Comparable {
    public static func < (lhs: ShippingLine, rhs: ShippingLine) -> Bool {
        return lhs.shippingID == rhs.shippingID &&
            lhs.methodID == rhs.methodID &&
            lhs.methodTitle < rhs.methodTitle
    }
}
