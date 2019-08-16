import Foundation

/// Represents a Refund request Entity
///
public struct Refund {
    
    /// Total amount to be refunded
    ///
    public let amount: String
    
    /// Optional refund reason
    ///
    public let reason: String?
    
    /// Optional Line items to be refunded
    ///
    public let items: [LineItemRefund]?
    
    public init(amount: String, reason: String?, items: [LineItemRefund]?) {
        self.amount = amount
        self.reason = reason
        self.items = items
    }
    
    public func toDictionary() -> [String: Any]{
        var dict: [String: Any] = ["amount": amount]
        
        if reason != nil{
            dict["reason"] = reason
        }
        
        if items != nil{
            dict["line_items"] = Dictionary(uniqueKeysWithValues: items!.map{ ($0.itemID, $0.toDictionary()) })
        }
        return dict
    }
}

// MARK: - Comparable Conformance
//
extension Refund: Comparable {
    public static func == (lhs: Refund, rhs: Refund) -> Bool {
        return lhs.amount == rhs.amount &&
            lhs.reason == rhs.reason &&
            NSDictionary(dictionary: lhs.toDictionary()).isEqual(to: rhs.toDictionary()) &&
            (lhs.items != nil && rhs.items != nil) ? lhs.items!.count == rhs.items!.count &&
                lhs.items!.sorted() == rhs.items!.sorted() : true
    }
    
    public static func < (lhs: Refund, rhs: Refund) -> Bool {
        return lhs.amount == rhs.amount
    }
}
