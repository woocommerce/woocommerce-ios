import Foundation

public extension WCPayCardBrand {
    /// Human-readable brand name for display. See `CardBrandDisplayName` for the shared source of truth.
    var displayName: String {
        switch self {
        case .amex:
            return CardBrandDisplayName.americanExpress
        case .diners:
            return CardBrandDisplayName.dinersClub
        case .discover:
            return CardBrandDisplayName.discover
        case .eftposAu:
            return CardBrandDisplayName.eftpos
        case .interac:
            return CardBrandDisplayName.interac
        case .jcb:
            return CardBrandDisplayName.jcb
        case .mastercard:
            return CardBrandDisplayName.mastercard
        case .unionpay:
            return CardBrandDisplayName.unionPay
        case .visa:
            return CardBrandDisplayName.visa
        case .cartesBancaires:
            return CardBrandDisplayName.cartesBancaires
        case .unknown:
            return CardBrandDisplayName.unknown
        }
    }
}
