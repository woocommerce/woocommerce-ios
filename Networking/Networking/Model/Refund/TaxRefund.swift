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

// MARK: - Comparable Conformance
//
extension TaxRefund: Comparable {
    public static func == (lhs: TaxRefund, rhs: TaxRefund) -> Bool {
        return lhs.taxIDLineItem == rhs.taxIDLineItem &&
            lhs.amount == rhs.amount
    }
    
    public static func < (lhs: TaxRefund, rhs: TaxRefund) -> Bool {
        return lhs.amount == rhs.amount
    }
}
