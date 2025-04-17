import Foundation

public enum POSItemType: CaseIterable {
    case product
    case variation
    case coupon
}

extension POSItemType {
    var storedSearchHistoryKey: String {
        switch self {
        case .product:
            return "product_search_terms"
        case .variation:
            return "variation_search_terms"
        case .coupon:
            return "coupon_search_terms"
        }
    }
}
