import Foundation

/// Human-readable card brand names — the single source of truth shared by the reader-reported
/// `CardBrand` and the server-reported `WCPayCardBrand`, so a brand reads the same wherever it
/// is shown (receipts, refunds, …).
///
/// Deliberately not localized: these are proper nouns whose spelling and casing are set by the
/// card networks' branding requirements (e.g. "Mastercard", "eftpos").
enum CardBrandDisplayName {
    static let visa = "Visa"
    static let americanExpress = "American Express"
    static let mastercard = "Mastercard"
    static let discover = "Discover"
    static let jcb = "JCB"
    static let dinersClub = "Diners Club"
    static let interac = "Interac"
    static let unionPay = "UnionPay"
    static let eftpos = "eftpos"
    static let cartesBancaires = "Cartes Bancaires"
    static let girocard = "girocard"

    /// `unknown` has no name to show.
    static let unknown = ""
}
