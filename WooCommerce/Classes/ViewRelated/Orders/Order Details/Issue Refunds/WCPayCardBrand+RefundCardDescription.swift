import Foundation
import Yosemite

extension WCPayCardBrand {
    /// A displayable brand name and last 4 digits for a card. These are deliberately not localized, always in English,
    /// because of various limitations on localization by the card companies. Care should be taken if localizing (some of)
    /// these brand names in future - e.g. Mastercard allows only English, or specific authorized versions in Chinese (translation),
    /// Arabic (transliteration), and Georgian (transliteration).
    ///
    /// Names taken from [Stripe's card branding in the API docs](https://stripe.com/docs/api/cards/object#card_object-brand):
    /// American Express, Diners Club, Discover, JCB, Mastercard, UnionPay, Visa, or Unknown.
    /// N.B. on review, we found that Mastercard should not have an uppercase "c" as it does in Stripe's documentation
    /// https://brand.mastercard.com/brandcenter/branding-requirements/mastercard.html#name
    func refundCardDescription(last4: String) -> String {
        String(format: refundCardDescriptionFormatString, last4)
    }

    var refundCardDescriptionFormatString: String {
        switch self {
        case .amex:
            return "•••• %1$@ (American Express)"
        case .diners:
            return "•••• %1$@ (Diners Club)"
        case .discover:
            return "•••• %1$@ (Discover)"
        case .eftposAu:
            return "•••• %1$@ (eftpos)"
        case .interac:
            return "•••• %1$@ (Interac)"
        case .jcb:
            return "•••• %1$@ (JCB)"
        case .mastercard:
            return "•••• %1$@ (Mastercard)"
        case .unionpay:
            return "•••• %1$@ (UnionPay)"
        case .visa:
            return "•••• %1$@ (Visa)"
        case .cartesBancaires:
            return "•••• %1$@ (Cartes Bancaires)"
        case .unknown:
            return "•••• %1$@"
        }
    }
}
