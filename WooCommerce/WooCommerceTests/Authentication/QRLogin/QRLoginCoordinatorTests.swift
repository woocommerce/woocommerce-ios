import Foundation
import Testing
import UIKit
import WordPressAuthenticator
@testable import WooCommerce

/// Tests for `QRLoginCoordinator` — the payload routing, mode branching, and
/// lifecycle that the manual test matrix otherwise covers end-to-end.
///
/// The coordinator drives a real `UINavigationController`; the tests keep it
/// out of a window so pushing a SwiftUI host view never triggers the live
/// flow's `.task`. Behaviour is observed through the pushed view-controller
/// stack, the injected callbacks, and the analytics spy.
@Suite(.timeLimit(.minutes(1)))
@MainActor
struct QRLoginCoordinatorTests {

    @Test func start_when_camera_mode_then_pushes_prologue_and_does_not_finish() {
        // Given
        let nav = UINavigationController()
        let spy = Spies()
        let coordinator = makeCoordinator(mode: .camera, navigationController: nav, spies: spy)

        // When
        coordinator.start()

        // Then — the dark prologue is the only screen and the coordinator stays
        // alive to keep driving the camera-mode stack.
        #expect(nav.viewControllers.count == 1)
        #expect(spy.finishedCount == 0)
        #expect(spy.analytics.flows == [.loginQR])
        #expect(spy.analytics.steps == [.qrPrologue])
    }

    @Test func start_when_deepLink_selfHosted_then_pushes_host_and_stays_alive() {
        // Given
        let nav = UINavigationController()
        let spy = Spies()
        let payload = QRLoginPayload.selfHosted(token: Self.selfHostedToken,
                                                siteURL: URL(string: "https://example.com")!)
        let coordinator = makeCoordinator(mode: .deepLink(payload: payload),
                                          navigationController: nav,
                                          spies: spy)

        // When
        coordinator.start()

        // Then — the live flow's host view is pushed; the coordinator must stay
        // alive to run the scan → poll → exchange pipeline.
        #expect(nav.viewControllers.count == 1)
        #expect(spy.finishedCount == 0)
    }

    @Test func start_when_deepLink_wpCom_then_pushes_host_and_stays_alive() {
        // Given
        let nav = UINavigationController()
        let spy = Spies()
        let payload = QRLoginPayload.wpCom(token: "abc:def", encrypted: "blob")
        let coordinator = makeCoordinator(mode: .deepLink(payload: payload),
                                          navigationController: nav,
                                          spies: spy)

        // When
        coordinator.start()

        // Then
        #expect(nav.viewControllers.count == 1)
        #expect(spy.finishedCount == 0)
    }

    @Test func start_when_deepLink_invalid_then_shows_error_and_tracks_failure() {
        // Given
        let nav = UINavigationController()
        let spy = Spies()
        let coordinator = makeCoordinator(mode: .deepLink(payload: .invalid),
                                          navigationController: nav,
                                          spies: spy)

        // When
        coordinator.start()

        // Then — an error screen is shown and a failure is tracked; the
        // coordinator waits on the "Scan a new code" CTA rather than finishing.
        #expect(nav.viewControllers.count == 1)
        #expect(spy.analytics.steps.last == .qrError)
        #expect(spy.analytics.failures.isEmpty == false)
        #expect(spy.finishedCount == 0)
    }

    @Test func start_when_deepLink_installQR_then_shows_error_and_tracks_failure() {
        // Given
        let nav = UINavigationController()
        let spy = Spies()
        let coordinator = makeCoordinator(mode: .deepLink(payload: .installQR),
                                          navigationController: nav,
                                          spies: spy)

        // When
        coordinator.start()

        // Then
        #expect(nav.viewControllers.count == 1)
        #expect(spy.analytics.steps.last == .qrError)
        #expect(spy.analytics.failures.isEmpty == false)
        #expect(spy.finishedCount == 0)
    }

    @Test func start_when_deepLink_siteURLOnly_then_finishes_coordinator() {
        // Given — a legacy site-URL-only payload routes to the WPA site-address
        // screen and, in deep-link mode, exits the QR-login surface.
        WordPressAuthenticator.initializeAuthenticator()
        let nav = UINavigationController()
        let spy = Spies()
        let payload = QRLoginPayload.siteURLOnly(siteURL: URL(string: "https://example.com")!)
        let coordinator = makeCoordinator(mode: .deepLink(payload: payload),
                                          navigationController: nav,
                                          spies: spy)

        // When
        coordinator.start()

        // Then — `finishIfDeepLink` releases the coordinator once routing is done.
        #expect(spy.finishedCount == 1)
    }

    @Test func finish_fires_onFinished_exactly_once_across_repeated_exits() {
        // Given — a deep-link self-hosted flow keeps the coordinator alive...
        let nav = UINavigationController()
        let spy = Spies()
        let firstPayload = QRLoginPayload.selfHosted(token: Self.selfHostedToken,
                                                     siteURL: URL(string: "https://example.com")!)
        let coordinator = makeCoordinator(mode: .deepLink(payload: firstPayload),
                                          navigationController: nav,
                                          spies: spy)
        coordinator.start()
        #expect(spy.finishedCount == 0)

        // When — re-feeding a terminal legacy payload routes + finishes, and a
        // second terminal payload would finish again if the one-shot guard
        // weren't there.
        let terminalPayload = QRLoginPayload.siteURLOnly(siteURL: URL(string: "https://example.com")!)
        WordPressAuthenticator.initializeAuthenticator()
        coordinator.presentDeepLink(payload: terminalPayload)
        coordinator.presentDeepLink(payload: terminalPayload)

        // Then — `onFinished` fired at most once.
        #expect(spy.finishedCount == 1)
    }

    @Test func presentDeepLink_when_camera_started_then_pushes_screen_on_top() {
        // Given — a camera-mode coordinator already presenting the prologue.
        let nav = UINavigationController()
        let spy = Spies()
        let coordinator = makeCoordinator(mode: .camera, navigationController: nav, spies: spy)
        coordinator.start()
        #expect(nav.viewControllers.count == 1)

        // When — a deep link arrives and is fed into the same coordinator.
        let payload = QRLoginPayload.selfHosted(token: Self.selfHostedToken,
                                                siteURL: URL(string: "https://example.com")!)
        coordinator.presentDeepLink(payload: payload)

        // Then — the host view is pushed on top of the prologue; no second
        // coordinator is needed.
        #expect(nav.viewControllers.count == 2)
        #expect(spy.finishedCount == 0)
    }
}

// MARK: - Helpers

private extension QRLoginCoordinatorTests {

    /// A 64-char alphanumeric token, the minimum the self-hosted parser accepts.
    static let selfHostedToken = String(repeating: "a", count: 64)

    /// Bundles the injected coordinator callbacks + analytics so tests can spy
    /// on lifecycle and tracking without reaching into the coordinator.
    @MainActor
    final class Spies {
        let analytics = SpyQRLoginAnalytics()
        private(set) var finishedCount = 0
        private(set) var successCount = 0
        private(set) var enterSiteURLCount = 0
        private(set) var showHelpCount = 0

        func onFinished() { finishedCount += 1 }
        func onSuccess() { successCount += 1 }
        func onEnterSiteURL() { enterSiteURLCount += 1 }
        func onShowHelp() { showHelpCount += 1 }
    }

    func makeCoordinator(mode: QRLoginCoordinator.Mode,
                         navigationController: UINavigationController,
                         spies: Spies) -> QRLoginCoordinator {
        QRLoginCoordinator(
            mode: mode,
            navigationController: navigationController,
            analytics: spies.analytics,
            onEnterSiteURL: { spies.onEnterSiteURL() },
            onShowHelp: { spies.onShowHelp() },
            onSuccess: { spies.onSuccess() },
            onFinished: { spies.onFinished() }
        )
    }
}

@MainActor
final class SpyQRLoginAnalytics: QRLoginAnalyticsTracking {
    private(set) var flows: [AuthenticatorAnalyticsTracker.Flow] = []
    private(set) var steps: [AuthenticatorAnalyticsTracker.Step] = []
    private(set) var clicks: [AuthenticatorAnalyticsTracker.ClickTarget] = []
    private(set) var failures: [String] = []

    func setFlow(_ flow: AuthenticatorAnalyticsTracker.Flow) { flows.append(flow) }
    func trackStep(_ step: AuthenticatorAnalyticsTracker.Step) { steps.append(step) }
    func trackClick(_ click: AuthenticatorAnalyticsTracker.ClickTarget) { clicks.append(click) }
    func trackFailure(_ failure: String) { failures.append(failure) }
}
