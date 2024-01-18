import UIKit

/// Card types used in Blaze campaign creation.
enum CreditCardType: String {
    case amex
    case diners
    case discover
    case interac
    case jcb
    case mastercard
    case unionpay
    case visa
    case unknown

    init(rawType: String) {
        self = CreditCardType(rawValue: rawType.lowercased()) ?? .unknown
    }
}

/// Implementation follows `WCPayCardBrand`.
extension CreditCardType {
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

    private func iconName(suffix: String) -> String {
        return "card-brand-\(suffix)"
    }
}