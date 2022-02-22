/// The various card brands for a card.
public enum CardBrand: String, CaseIterable, Codable {
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
        case .unknown:
            return "unknown"
        }
    }
}
