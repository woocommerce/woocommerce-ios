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
