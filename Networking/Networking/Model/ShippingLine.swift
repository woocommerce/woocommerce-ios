import Foundation
import Codegen

/// Represents a Shipping Line Entity.
///
public struct ShippingLine: Codable, Equatable, GeneratedFakeable {
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

    /// Shipping Method struct initializer.
    ///
    public init(shippingID: Int64,
                methodTitle: String,
                methodID: String?,
                total: String,
                totalTax: String,
                taxes: [ShippingLineTax]) {

        self.shippingID = shippingID
        self.methodTitle = methodTitle
        self.methodID = methodID
        self.total = total
        self.totalTax = totalTax
        self.taxes = taxes
    }
}

// MARK: Codable
extension ShippingLine {

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
