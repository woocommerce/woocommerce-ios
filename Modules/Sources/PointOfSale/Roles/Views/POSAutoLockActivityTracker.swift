import SwiftUI

/// Keeps the POS auto-lock timer alive while the operator is actively using POS.
///
/// Attach via `.posAutoLockActivityTracking(...)` at the POS root. Two behaviors:
///
/// 1. A zero-distance `DragGesture` observes every tap/scroll and pokes
///    `resetInactivityTimer()`. Calls are throttled so scroll gestures don't
///    overwhelm the provider.
/// 2. While any payment is in flight (card or cash), a background pulse resets
///    the timer every few seconds so long `processingPayment` waits can't lock
///    the register mid-transaction. A single state transition (e.g. acceptingCard
///    -> processingPayment) also resets the timer via the `.onChange` hook.
///
/// This is view-layer glue only. The provider doesn't know about payments.
private struct POSAutoLockActivityTrackingModifier: ViewModifier {
    let permissions: POSPermissionProviding
    let paymentModel: POSPaymentModel?

    @State private var lastResetAt: Date = .distantPast

    /// Minimum gap between resets from user-input gestures. Scrolls fire drag
    /// events at ~60Hz; we only need to reset once per second.
    private static let gestureThrottle: TimeInterval = 1.0

    /// How often to pulse the timer while payment is mid-flight. Must be shorter
    /// than any auto-lock interval we expect to see in production.
    private static let paymentPulseInterval: TimeInterval = 5.0

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0).onChanged { _ in
                    resetThrottled()
                }
            )
            .onChange(of: paymentModel?.paymentState) { _, _ in
                // Reset on every card/cash state transition. Catches the common
                // case of a payment flow where the user isn't actively touching
                // the screen but the system is progressing.
                resetThrottled()
            }
            .task(id: paymentModel?.paymentState.isAutoLockSuppressing ?? false) {
                guard paymentModel?.paymentState.isAutoLockSuppressing == true else { return }
                while !Task.isCancelled,
                      paymentModel?.paymentState.isAutoLockSuppressing == true {
                    resetThrottled()
                    try? await Task.sleep(for: .seconds(Self.paymentPulseInterval))
                }
            }
    }

    private func resetThrottled() {
        let now = Date()
        guard now.timeIntervalSince(lastResetAt) >= Self.gestureThrottle else { return }
        lastResetAt = now
        permissions.resetInactivityTimer()
    }
}

extension View {
    /// Installs POS auto-lock activity tracking: gesture-driven resets plus a
    /// pulse that suppresses auto-lock during active payment flows.
    ///
    /// - Parameters:
    ///   - permissions: The permission provider whose `resetInactivityTimer()` we call.
    ///   - paymentModel: The payment model whose state we observe. Pass `nil` before
    ///     it's ready; the modifier tolerates the nil and only starts the payment pulse
    ///     once it's attached.
    func posAutoLockActivityTracking(permissions: POSPermissionProviding,
                                     paymentModel: POSPaymentModel?) -> some View {
        modifier(POSAutoLockActivityTrackingModifier(permissions: permissions, paymentModel: paymentModel))
    }
}

extension PointOfSalePaymentState {
    /// True while a payment is mid-flight. Used to suppress the POS auto-lock
    /// so the register doesn't lock in the middle of a transaction.
    var isAutoLockSuppressing: Bool {
        let cardInFlight: Bool = {
            switch card {
            case .validatingOrder, .preparingReader, .acceptingCard, .cardInserted,
                 .processingPayment, .cardPaymentSuccessful:
                return true
            case .idle, .validatingOrderError, .paymentIntentCreationError, .paymentError:
                return false
            }
        }()
        let cashInFlight: Bool = {
            switch cash {
            case .collectingCash, .paymentSuccess:
                return true
            case .idle:
                return false
            }
        }()
        return cardInFlight || cashInFlight
    }
}
