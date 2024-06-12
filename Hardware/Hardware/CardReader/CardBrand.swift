import Codegen

/// The various card brands for a card.
@frozen public enum CardBrand: String, CaseIterable, Codable, GeneratedFakeable {
    /// Visa card
    case visa

    /// American Express card
    case amex

    /// MasterCard card
    case masterCard

    /// Discover card
    case discover

    /// JCB card
    case jcb

    /// Diners Club card
    case dinersClub

    /// Interac unbranded card
    case interac

    /// Union Pay card
    case unionPay

    /// Eftpos Australia card
    case eftposAu

    /// An unknown card brand
    case unknown
}

extension CardBrand {
    // The initializer for Bundle only works with class types.
    // We use this class as a shortcut to find the bundle for the CardBrand enum type
    private class _Bundle {}

    private var iconURL: URL! {
        Bundle(for: CardBrand._Bundle.self)
            .url(forResource: iconName, withExtension: "svg")
    }

    /// Icon that represents the brand in SVG format
    /// Since we mostly use these in HTML for receipts, we are reading the files directly instead of using UIImage
    var iconData: Data! {
        try? Data(contentsOf: iconURL)
    }

    /// Icon name to be used for CSS classes
    var iconName: String {
        switch self {
        case .visa:
            return "visa"
        case .amex:
            return "amex"
        case .masterCard:
            return "mastercard"
        case .discover:
            return "discover"
        case .jcb:
            return "jcb"
        case .dinersClub:
            return "diners"
        case .interac:
            return "interac"
        case .unionPay:
            return "unionpay"
        case .unknown, .eftposAu:
            return "unknown"
        }
    }
}
