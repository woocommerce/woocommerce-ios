import Foundation

public extension WCPayCardBrand {
    /// Human-readable brand name for display.
    ///
    /// Deliberately not localized: these are proper nouns whose spelling and casing are set by the
    /// card networks' branding requirements (e.g. "Mastercard", "eftpos"). `unknown` has no name to show.
    var displayName: String {
        switch self {
        case .amex:
            return "American Express"
        case .diners:
            return "Diners Club"
        case .discover:
            return "Discover"
        case .eftposAu:
            return "eftpos"
        case .interac:
            return "Interac"
        case .jcb:
            return "JCB"
        case .mastercard:
            return "Mastercard"
        case .unionpay:
            return "UnionPay"
        case .visa:
            return "Visa"
        case .cartesBancaires:
            return "Cartes Bancaires"
        case .unknown:
            return ""
        }
    }
}
