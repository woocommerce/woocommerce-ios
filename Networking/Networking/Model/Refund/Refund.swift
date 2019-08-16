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
    
    /// Line items
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
