import Foundation


/// Represents a Shipping Method Entity.
///
public struct ShippingMethod: Decodable {
    public let shippingId: Int
    public let methodTitle: String
    public let methodId: String
    public let total: String
    public let totalTax: String
    
    /// Shipping Method struct initializer.
    ///
    public init(shippingId: Int,
                methodTitle: String,
                methodId: String,
                total: String,
                totalTax: String) {
        
        self.shippingId = shippingId
        self.methodTitle = methodTitle
        self.methodId = methodId
        self.total = total
        self.totalTax = totalTax
    }
    
    
    /// The public initializer for Shipping Method.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let shippingId = try container.decode(Int.self, forKey: .shippingId)
        let methodTitle = try container.decode(String.self, forKey: .methodTitle)
        let methodId = try container.decode(String.self, forKey: .methodId)
        let total = try container.decode(String.self, forKey: .total)
        let totalTax = try container.decode(String.self, forKey: .totalTax)
        
        self.init(shippingId: shippingId,
                  methodTitle: methodTitle,
                  methodId: methodId,
                  total: total,
                  totalTax: totalTax)
    }
}


/// Defines all of the Shipping Method CodingKeys
///
private extension ShippingMethod {
    
    enum CodingKeys: String, CodingKey {
        case shippingId            = "id"
        case methodTitle           = "method_title"
        case methodId              = "method_id"
        case total                 = "total"
        case totalTax              = "total_tax"
    }
}


// MARK: - Comparable Conformance
//
extension ShippingMethod: Comparable {
    public static func == (lhs: ShippingMethod, rhs: ShippingMethod) -> Bool {
        return lhs.shippingId == rhs.shippingId &&
            lhs.methodTitle == rhs.methodTitle &&
            lhs.methodId == rhs.methodId &&
            lhs.total == rhs.total &&
            lhs.totalTax == rhs.totalTax
    }
    
    public static func < (lhs: ShippingMethod, rhs: ShippingMethod) -> Bool {
        return lhs.shippingId == rhs.shippingId &&
            lhs.methodId == rhs.methodId &&
            lhs.methodTitle < rhs.methodTitle
    }
}
