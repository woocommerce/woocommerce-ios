import Foundation
import Yosemite

extension WCPayCardBrand {
    /// Icon that represents the card brand in SVG format
    ///
    var icon: UIImage? {
        UIImage(named: iconName)
    }

    /// Icon name to be used for the card icon UIImage
    var iconName: String {
        switch self {
        case .visa:
            return "card-brand-visa"
        case .amex:
            return "card-brand-amex"
        case .mastercard:
            return "card-brand-mastercard"
        case .discover:
            return "card-brand-discover"
        case .jcb:
            return "card-brand-jcb"
        case .diners:
            return "card-brand-diners"
        case .unionpay:
            return "card-brand-unionpay"
        default:
            return "card-brand-unknown"
        }
    }
}
