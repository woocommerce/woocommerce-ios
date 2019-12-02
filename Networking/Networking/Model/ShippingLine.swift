import Foundation


/// Represents a Shipping Line Entity.
///
public struct ShippingLine: Decodable {
    public let shippingID: Int
    public let methodTitle: String
    public let methodID: String
    public let total: String
    public let totalTax: String

    /// Shipping Method struct initializer.
    ///
    public init(shippingID: Int,
                methodTitle: String,
                methodID: String,
                total: String,
                totalTax: String) {

        self.shippingID = shippingID
        self.methodTitle = methodTitle
        self.methodID = methodID
        self.total = total
        self.totalTax = totalTax
    }


    /// The public initializer for Shipping Line.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let shippingID = try container.decode(Int.self, forKey: .shippingID)
        let methodTitle = try container.decode(String.self, forKey: .methodTitle)
        let methodID = try container.decode(String.self, forKey: .methodID)
        let total = try container.decode(String.self, forKey: .total)
        let totalTax = try container.decode(String.self, forKey: .totalTax)

        self.init(shippingID: shippingID,
                  methodTitle: methodTitle,
                  methodID: methodID,
                  total: total,
                  totalTax: totalTax)
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
    }
}


// MARK: - Comparable Conformance
//
extension ShippingLine: Comparable {
    public static func == (lhs: ShippingLine, rhs: ShippingLine) -> Bool {
        return lhs.shippingID == rhs.shippingID &&
            lhs.methodTitle == rhs.methodTitle &&
            lhs.methodID == rhs.methodID &&
            lhs.total == rhs.total &&
            lhs.totalTax == rhs.totalTax
    }

    public static func < (lhs: ShippingLine, rhs: ShippingLine) -> Bool {
        return lhs.shippingID == rhs.shippingID &&
            lhs.methodID == rhs.methodID &&
            lhs.methodTitle < rhs.methodTitle
    }
}
