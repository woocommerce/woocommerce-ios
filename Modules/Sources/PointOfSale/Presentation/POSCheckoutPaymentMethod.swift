import Foundation

/// A payment method offered in the totals view's bottom buttons row.
///
/// Mirrors the Android `WooPosPaymentMethod` enum. Cases are ordered by precedence —
/// the first method in a `[POSCheckoutPaymentMethod]` array is rendered as the primary
/// (filled) button; the rest are outlined. The TotalsView builds this array from the
/// current payment + reader state and any feature flags.
enum POSCheckoutPaymentMethod: Hashable {
    /// Apple's built-in (Tap to Pay on iPhone) reader. Phone-only — not surfaced
    /// when TTP availability resolves to `.unavailable`.
    case tapToPay
    /// Bluetooth card reader (Stripe M2, WisePad, etc.). The "Connect your reader" CTA
    /// also lives behind this method when no reader is connected.
    case cardReader
    /// Manually entered cash payment.
    case cashPayment
    /// Scan-to-Pay (QR code) checkout. Feature-flag-gated via `.pointOfSaleScanToPay`.
    /// Surfaced inline in the promoted-no-card layout, and behind the
    /// `.otherPaymentMethods` sheet on the card-enabled layout.
    case scanToPay
    /// Mark order as paid (out-of-band payment confirmation). Feature-flag-gated via
    /// `.pointOfSaleMarkOrderAsPaid`. Same surfacing rules as `.scanToPay`.
    case markOrderAsPaid
    /// Opens the "Other payment methods" sheet exposing Scan-to-Pay and Mark-as-Paid
    /// (the subset that is feature-flag-on). Appended to the row on card-enabled stores
    /// whenever at least one secondary method is enabled, so the merchant can always
    /// reach the secondary methods even on iPad-no-TTP card flows where neither
    /// `useCashAndOtherMethodsBottomStrip` nor the promoted-no-card layout applies.
    case otherPaymentMethods
}
