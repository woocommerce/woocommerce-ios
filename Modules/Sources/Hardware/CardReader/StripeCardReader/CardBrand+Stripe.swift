#if !targetEnvironment(macCatalyst)
import StripeTerminal

extension CardBrand {

    /// Convenience initializer
    /// - Parameter reader: An instance of a StripeTerminal.CardBrand
    init(brand: StripeTerminal.CardBrand) {
        switch brand {
        case .visa:
            self = .visa
        case .amex:
            self = .amex
        case .masterCard:
            self = .masterCard
        case .discover:
            self = .discover
        case .JCB:
            self = .jcb
        case .dinersClub:
            self = .dinersClub
        case .interac:
            self = .interac
        case .unionPay:
            self = .unionPay
        case .eftposAu:
            self = .eftposAu
        case .cartesBancaires, .girocard:
            // TODO: new CardBrand cases would need SVG icons for receipts, just shows generic icon on receipts
            self = .unknown
        case .unknown:
            self = .unknown
        @unknown default:
            self = .unknown
        }
    }
}
#endif
