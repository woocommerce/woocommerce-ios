import Foundation

/// Pure resolver that builds the ordered list of `POSCheckoutPaymentMethod` values rendered
/// at the bottom of the totals view.
///
/// Extracted from `TotalsView` so the branching between "card-enabled" and "promoted no-card"
/// layouts can be unit-tested without standing up a SwiftUI environment. `TotalsView` computes
/// the inputs from its observed models and feature flags, then calls `resolve` to get the
/// ordered method list.
///
/// Ordering rules:
/// - **Card-enabled stores** (`isPOSCardPaymentEnabled == true`): optional `.tapToPay`, optional
///   `.cardReader`, then always `.cashPayment`. The first slot renders as the primary (filled)
///   button via `POSCheckoutPaymentButtonsRow`; the rest are outlined.
/// - **No-card stores** (`isPOSCardPaymentEnabled == false`): always `.cashPayment` first
///   (the primary CTA), followed by `.scanToPay` and `.markOrderAsPaid` if their feature flags
///   are enabled. Rendered by `POSCheckoutPromotedPaymentButtons` as a 1+n layout (Cash filled
///   full-width on row 1; secondary methods in an HStack on row 2).
///
/// Returns an empty array when `isCashButtonVisible == false` — the cash-button visibility
/// guard takes precedence over both layouts so the bottom row collapses to nothing during
/// flows where the totals row shouldn't be tappable (syncing, reconnecting, zero-total, …).
enum POSCheckoutPaymentMethodResolver {
    static func resolve(isPOSCardPaymentEnabled: Bool,
                        isCashButtonVisible: Bool,
                        isReaderDisconnected: Bool,
                        isTapToPayAvailable: Bool,
                        isScanToPayEnabled: Bool,
                        isMarkOrderAsPaidEnabled: Bool) -> [POSCheckoutPaymentMethod] {
        guard isCashButtonVisible else {
            return []
        }

        guard isPOSCardPaymentEnabled else {
            var methods: [POSCheckoutPaymentMethod] = [.cashPayment]
            if isScanToPayEnabled {
                methods.append(.scanToPay)
            }
            if isMarkOrderAsPaidEnabled {
                methods.append(.markOrderAsPaid)
            }
            return methods
        }

        var methods: [POSCheckoutPaymentMethod] = []
        if isTapToPayAvailable {
            methods.append(.tapToPay)
        }
        if isReaderDisconnected {
            methods.append(.cardReader)
        }
        methods.append(.cashPayment)
        return methods
    }
}
