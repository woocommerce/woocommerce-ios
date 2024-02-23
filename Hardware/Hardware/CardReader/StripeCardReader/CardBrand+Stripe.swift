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
        case .unknown:
            self = .unknown
        @unknown default:
            self = .unknown
        }
    }
}
#endif
