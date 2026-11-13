import Foundation
import Hardware

extension CardBrand {
    /// Human-readable brand name for display. See `CardBrandDisplayName` for the shared source of truth.
    var displayName: String {
        switch self {
        case .visa:
            return CardBrandDisplayName.visa
        case .amex:
            return CardBrandDisplayName.americanExpress
        case .masterCard:
            return CardBrandDisplayName.mastercard
        case .discover:
            return CardBrandDisplayName.discover
        case .jcb:
            return CardBrandDisplayName.jcb
        case .dinersClub:
            return CardBrandDisplayName.dinersClub
        case .interac:
            return CardBrandDisplayName.interac
        case .unionPay:
            return CardBrandDisplayName.unionPay
        case .eftposAu:
            return CardBrandDisplayName.eftpos
        case .cartesBancaires:
            return CardBrandDisplayName.cartesBancaires
        case .girocard:
            return CardBrandDisplayName.girocard
        case .unknown:
            return CardBrandDisplayName.unknown
        }
    }
}
