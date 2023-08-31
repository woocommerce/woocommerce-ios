import Foundation

enum ShippingLabelHazmatCategory: String, CaseIterable {
    case firstCategory
    case secondCategory
    case thirdCategory
    case none
    
    var localizedName: String {
        switch self {
        case .firstCategory:
            return "First Category"
        case .secondCategory:
            return "Second Category"
        case .thirdCategory:
            return "Third Category"
        case .none:
            return "Select a category"
        }
    }
}

extension ShippingLabelHazmatCategory {
    enum Localization {
        
    }
}
