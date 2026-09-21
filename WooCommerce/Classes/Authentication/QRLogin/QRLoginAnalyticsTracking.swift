import Foundation
import WordPressAuthenticator

/// Façade around `AuthenticatorAnalyticsTracker` for the QR-login flow.
/// Lets tests substitute a spy instead of poking at the shared singleton, and
/// pins the `flow = login_qr` invariant in one place.
@MainActor
protocol QRLoginAnalyticsTracking {
    func trackStep(_ step: AuthenticatorAnalyticsTracker.Step)
    func trackClick(_ click: AuthenticatorAnalyticsTracker.ClickTarget)
    func trackFailure(_ failure: String)
    func setFlow(_ flow: AuthenticatorAnalyticsTracker.Flow)
    /// Sets the current step without emitting an event, so later interaction
    /// events carry it. Mirrors the flow-only `setFlow(_:)`.
    func setStep(_ step: AuthenticatorAnalyticsTracker.Step)
}

@MainActor
struct DefaultQRLoginAnalyticsTracking: QRLoginAnalyticsTracking {
    private let tracker: AuthenticatorAnalyticsTracker

    init(tracker: AuthenticatorAnalyticsTracker = .shared) {
        self.tracker = tracker
    }

    func setFlow(_ flow: AuthenticatorAnalyticsTracker.Flow) {
        tracker.set(flow: flow)
    }

    func setStep(_ step: AuthenticatorAnalyticsTracker.Step) {
        tracker.set(step: step)
    }

    func trackStep(_ step: AuthenticatorAnalyticsTracker.Step) {
        tracker.track(step: step)
    }

    func trackClick(_ click: AuthenticatorAnalyticsTracker.ClickTarget) {
        tracker.track(click: click)
    }

    func trackFailure(_ failure: String) {
        tracker.track(failure: failure)
    }
}
