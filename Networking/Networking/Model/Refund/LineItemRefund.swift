import Foundation

/// Represents a Line Item to be Refunded
///
public struct LineItemRefund {
    
    ///  ID from the order's line_items
    ///
    public let itemID: String
    
    /// Item quantity
    ///
    public let quantity: Int
    
    /// Total refunded amount for this item
    ///
    public let refundTotal: String?
    
    /// Taxes to refund
    public let refundTax: [TaxRefund]?
    
    /// Line Item Refund struct initializer
    ///
    public init(itemID: String, quantity: Int, refundTotal: String?, refundTax: [TaxRefund]?) {
        self.itemID = itemID
        self.quantity = quantity
        self.refundTotal = refundTotal
        self.refundTax = refundTax
    }
    
    public func toDictionary() -> [String: Any] {
        var dict: [String: Any] = ["quantity": quantity]
        
        if refundTotal != nil{
            dict["refund_total"] = refundTotal
        }
        
        if refundTax != nil{
            dict["refund_tax"] = Dictionary(uniqueKeysWithValues: refundTax!.map{ ($0.taxIDLineItem, $0.amount) })
        }
        return dict
    }
}
