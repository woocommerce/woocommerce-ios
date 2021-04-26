/// The various card brands for a card.
public enum CardBrand {
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
