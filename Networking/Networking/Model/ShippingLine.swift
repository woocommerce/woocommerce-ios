import Foundation


/// Represents a Shipping Line Entity.
///
public struct ShippingLine: Decodable, Equatable, GeneratedFakeable {
    public let shippingID: Int64
    public let methodTitle: String
    public let methodID: String
    public let total: String
    public let totalTax: String
    public let taxes: [ShippingLineTax]

    /// Shipping Method struct initializer.
    ///
    public init(shippingID: Int64,
                methodTitle: String,
                methodID: String,
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
