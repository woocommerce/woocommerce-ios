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
            return iconName(suffix: "visa")
        case .amex:
            return iconName(suffix: "amex")
        case .mastercard:
            return iconName(suffix: "mastercard")
        case .discover:
            return iconName(suffix: "discover")
        case .interac:
            return iconName(suffix: "interac")
        case .jcb:
            return iconName(suffix: "jcb")
        case .diners:
            return iconName(suffix: "diners")
        case .unionpay:
            return iconName(suffix: "unionpay")
        default:
            return iconName(suffix: "unknown")
        }
    }

    var iconAspectHorizontal: CGFloat {
        switch self {
        case .interac:
            return 1
        case .diners:
            return 1.3684
        default:
            return 1.58
        }
    }

    private func iconName(suffix: String) -> String {
        return "card-brand-\(suffix)"
    }
}
