import Foundation

/// Pure resolver that builds the ordered list of `POSCheckoutPaymentMethod` values rendered
/// at the bottom of the totals view's `POSCheckoutPaymentButtonsRow`.
///
/// Extracted from `TotalsView` so the branching can be unit-tested without standing up a
/// SwiftUI environment. `TotalsView` computes the inputs from its observed models and
/// feature flags, then calls `resolve` to get the ordered method list.
///
/// Ordering rules:
/// - **Card-enabled stores** (`isPOSCardPaymentEnabled == true`): optional `.tapToPay`, optional
///   `.cardReader`, always `.cashPayment`, then `.otherPaymentMethods` whenever any secondary
///   method is feature-flagged on.
/// - **No-card stores** (`isPOSCardPaymentEnabled == false`): always `.cashPayment` first, then
///   `.otherPaymentMethods` when any secondary method is feature-flagged on. The secondary
///   methods (Scan-to-Pay, Mark-as-Paid) live inside the `POSOtherPaymentMethodsSheet` sheet
///   that the button opens — same affordance pattern as card-enabled phones.
///
/// The first slot renders as the primary (filled) button via `POSCheckoutPaymentButtonsRow`;
/// the rest are outlined.
///
/// Returns an empty array when `isCashButtonVisible == false` — the cash-button visibility
/// guard takes precedence so the bottom row collapses to nothing during flows where the
/// totals row shouldn't be tappable (syncing, reconnecting, zero-total, …).
///
/// Note: iPad uses a dedicated `SecondaryPaymentButtons` view (literal restoration of the
/// design from PR #17080) that doesn't go through this resolver. The resolver's array drives
/// the phone path through `POSCheckoutPaymentButtonsRow`.
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

        let isAnySecondaryMethodEnabled = isScanToPayEnabled || isMarkOrderAsPaidEnabled

        guard isPOSCardPaymentEnabled else {
            // No card-present payments in this country (Brazil, Japan, Mexico, …) or
            // explicitly disabled in POS (Canada). Render Cash as the primary CTA plus an
            // "Other payment methods" entry into the existing sheet — same shape as
            // card-enabled phones, just without the card-reader / TTP slots.
            var methods: [POSCheckoutPaymentMethod] = [.cashPayment]
            if isAnySecondaryMethodEnabled {
                methods.append(.otherPaymentMethods)
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
        // Surface the "Other payment methods" sheet as a row slot whenever there's
        // anything to put inside it. Without this, phone merchants in non-TTP
        // card-supported countries (FR, DE, IE, NL, AT, BE, FI, IT, LU, PT, ES, SG,
        // NZ, AU, PR) have no way to reach Scan-to-Pay / Mark-as-Paid.
        if isAnySecondaryMethodEnabled {
            methods.append(.otherPaymentMethods)
        }
        return methods
    }
}
