import Codegen
import Foundation

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

    /// Cartes Bancaires card
    case cartesBancaires

    /// Girocard card
    case girocard

    /// An unknown card brand
    case unknown
}

extension CardBrand {

    private var iconURL: URL! {
        Bundle.hardware.url(forResource: iconName, withExtension: "svg")
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
        case .unknown, .eftposAu, .cartesBancaires, .girocard:
            return "unknown"
        }
    }
}
