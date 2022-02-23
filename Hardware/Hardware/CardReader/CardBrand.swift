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

    //TODO: Add Interac here

    /// An unknown card brand
    case unknown
}

extension CardBrand: CustomStringConvertible {
    public var description: String {
        switch self {
        case .visa:
            return Localization.visa
        case .amex:
            return Localization.amex
        case .masterCard:
            return Localization.masterCard
        case .discover:
            return Localization.discover
        case .jcb:
            return Localization.jcb
        case .dinersClub:
            return Localization.dinersClub
        case .unknown:
            return Localization.other
        }
    }
}


private extension CardBrand {
    enum Localization {
        static let visa = NSLocalizedString(
            "Visa",
            comment: "A credit card brand"
        )

        static let amex = NSLocalizedString(
            "American Express",
            comment: "A credit card brand"
        )

        static let masterCard = NSLocalizedString(
            "MasterCard",
            comment: "A credit card brand"
        )

        static let discover = NSLocalizedString(
            "Discover",
            comment: "A credit card brand"
        )

        static let jcb = NSLocalizedString(
            "JCB",
            comment: "A credit card brand"
        )

        static let dinersClub = NSLocalizedString(
            "Diners Club",
            comment: "A credit card brand"
        )

        static let other = NSLocalizedString(
            "Other",
            comment: "A credit card brand"
        )
    }
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
