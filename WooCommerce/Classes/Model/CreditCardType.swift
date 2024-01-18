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
        iconName(suffix: rawValue)
    }

    private func iconName(suffix: String) -> String {
        return "card-brand-\(suffix)"
    }
}
