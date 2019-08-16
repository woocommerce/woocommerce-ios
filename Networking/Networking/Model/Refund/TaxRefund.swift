import Foundation

/// Represents a Tax Refund Entity
///
public struct TaxRefund {
    
    /// Tax ID for line item
    ///
    public let taxIDLineItem: String
    
    /// Product tax amount
    ///
    public let amount: String
    
    public init(taxIDLineItem: String, amount: String) {
        self.taxIDLineItem = taxIDLineItem
        self.amount = amount
    }
}
