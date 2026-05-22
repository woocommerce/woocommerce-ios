import AVFoundation
import AuthenticationServices
import SwiftUI
import UIKit
import WordPressAuthenticator

/// Drives the QR-login UI flow end-to-end.
///
/// Modes:
///   - `.camera` (default): prologue → scanner → live flow. Used when the
///     coordinator is entered from the standard login surface.
///   - `.deepLink(payload:)`: skip prologue + scanner, feed the parsed
///     payload straight into the live flow. Used when a `woocommerce://qr-login`
///     URL arrives (Layer 6).
///
/// Cancel / scan-again behaviour differs by mode (spec §4.2): camera mode
/// returns to the scanner; deep-link mode dismisses the QR-login UI entirely
/// so the merchant lands back where the deep link was opened from.
@MainActor
final class QRLoginCoordinator {

    enum Mode {
        case camera
        case deepLink(payload: QRLoginPayload)
    }

    private let mode: Mode
    private let navigationController: UINavigationController
    private let parser: QRLoginPayloadParser
    private let cameraPermissionChecker: QRLoginCameraPermissionCheckerProtocol
    private let analytics: QRLoginAnalyticsTracking
    private let onEnterSiteURL: () -> Void
    private let onShowHelp: () -> Void
    private let onSuccess: () -> Void

    /// Invoked once when the QR-login surface is left for good — success,
    /// back-out, deep-link exit, navigating to a fallback login, or a wp.com
    /// magic-link handoff — so the owner can release its reference to this
    /// coordinator. Scoping the lifetime here (not just on success) keeps a
    /// stale coordinator from being reused by the deep-link entry point.
    private let onFinished: () -> Void

    /// Guards `onFinished` so it fires at most once.
    private var didFinish = false

    /// The prologue screen, held weakly so "Scan a new code" can pop back to it
    /// and present a fresh scanner. The previous scanner latches onto its
    /// consumed payload and the camera session keeps running, so it can never
    /// deliver a second result — it must be replaced, not reused.
    private weak var prologueViewController: UIViewController?

    init(mode: Mode = .camera,
         navigationController: UINavigationController,
         parser: QRLoginPayloadParser = QRLoginPayloadParser(),
         cameraPermissionChecker: QRLoginCameraPermissionCheckerProtocol = DefaultQRLoginCameraPermissionChecker(),
         analytics: QRLoginAnalyticsTracking? = nil,
         onEnterSiteURL: @escaping () -> Void,
         onShowHelp: @escaping () -> Void,
         onSuccess: @escaping () -> Void,
         onFinished: @escaping () -> Void) {
        self.mode = mode
        self.navigationController = navigationController
        self.parser = parser
        self.cameraPermissionChecker = cameraPermissionChecker
        // `DefaultQRLoginAnalyticsTracking()` is @MainActor-isolated; can't be
        // a default parameter expression. The coordinator is @MainActor so
        // constructing it in the body is fine.
        self.analytics = analytics ?? DefaultQRLoginAnalyticsTracking()
        self.onEnterSiteURL = onEnterSiteURL
        self.onShowHelp = onShowHelp
        self.onSuccess = onSuccess
        self.onFinished = onFinished
    }

    /// Entry point. The coordinator manages its own UI from here on.
    func start() {
        analytics.setFlow(.loginQR)
        switch mode {
        case .camera:
            showPrologue()
        case .deepLink(let payload):
            handleScanned(payload: payload)
        }
    }

    /// Feeds a deep-link payload into the live flow on an already-started
    /// coordinator. Used when a `woocommerce://qr-login` URL arrives while this
    /// coordinator is already presenting the prologue — reusing it avoids
    /// orphaning a second coordinator on the same navigation stack.
    func presentDeepLink(payload: QRLoginPayload) {
        handleScanned(payload: payload)
    }
}

// MARK: - Prologue + scanner

private extension QRLoginCoordinator {

    func showPrologue() {
        analytics.trackStep(.qrPrologue)
        let view = QRLoginPrologueView(
            onBackTapped: { [weak self] in self?.handlePrologueBack() },
            onHelpTapped: { [weak self] in self?.showHelp() },
            onScanTapped: { [weak self] in self?.handleScanCTA() },
            onSiteAddressTapped: { [weak self] in self?.fallbackToSiteAddress() },
            onURLTapped: { Self.copyLoginURL() }
        )
        // The dark prologue hides the shared navigation bar and draws its own
        // light Back / Help controls over the bubble background.
        prologueViewController = pushScreen(view,
                                            navigationBarStyle: .hidden,
                                            prefersLightStatusBar: true,
                                            showsHelpButton: false)
    }

    func handleScanCTA() {
        analytics.trackClick(.qrLoginScan)
        presentScannerAfterCameraPermissionCheck()
    }

    /// Checks camera permission — requesting it when undetermined — and either
    /// presents the scanner or the appropriate denial alert. Shared by the
    /// prologue "Scan QR code" CTA and the error "Scan a new code" CTA so both
    /// honour the permission gate (spec §4.1.1) rather than pushing a scanner
    /// that has no camera access.
    func presentScannerAfterCameraPermissionCheck() {
        Task { @MainActor in
            switch cameraPermissionChecker.status {
            case .authorized:
                showScanner()
            case .notDetermined:
                analytics.trackClick(.qrCameraPermissionDialogShown)
                let granted = await cameraPermissionChecker.requestAccess()
                analytics.trackClick(granted ? .qrCameraPermissionGranted : .qrCameraPermissionDenied)
                if granted {
                    showScanner()
                } else {
                    showFirstDenialAlert()
                }
            case .denied:
                showPermanentlyDeniedAlert()
            case .restricted:
                showPermanentlyDeniedAlert()
            @unknown default:
                showPermanentlyDeniedAlert()
            }
        }
    }

    func showScanner() {
        analytics.trackStep(.qrScan)
        let view = QRLoginScannerView(
            onScannedPayload: { [weak self] payload in
                guard let self else { return }
                let parsed = self.parser.parse(payload)
                self.handleScanned(payload: parsed)
            },
            onCancel: { [weak self] in self?.popScanner() }
        )
        // The scanner is full-bleed camera UI with its own in-view chrome, so it
        // keeps the navigation bar hidden and does not use the toolbar Help item.
        pushScreen(view, navigationBarStyle: .hidden, showsHelpButton: false)
    }

    func popScanner() {
        navigationController.popViewController(animated: true)
    }

    func fallbackToSiteAddress() {
        analytics.trackClick(.qrLoginFallback)
        handleEnterSiteURL()
    }

    static func copyLoginURL() {
        UIPasteboard.general.string = WooConstants.qrLoginInstructionsURL
        // Snackbar / toast is owned by the prologue view — for now a Notice via
        // NoticePresenter would belong, but presenting it requires a host
        // controller. Left as a follow-up — the clipboard side is the
        // load-bearing part.
    }
}

// MARK: - Live flow

private extension QRLoginCoordinator {

    func handleScanned(payload: QRLoginPayload) {
        switch payload {
        case let .selfHosted(token, siteURL):
            let strategy = SelfHostedQRLoginStrategy(token: token, siteURL: siteURL)
            showHostView(with: strategy)

        case let .wpCom(token, encrypted):
            let strategy = WPComQRLoginStrategy(
                token: token,
                encrypted: encrypted,
                magicLinkOpener: { [weak self] url in
                    self?.openMagicLink(url)
                }
            )
            showHostView(with: strategy)

        case let .magicLink(url):
            // §10.1: hand the URL to the in-app auth session. WP.com redirects
            // to woocommerce://magic-login, captured by the session. Finishing
            // is handled per outcome inside `openMagicLink`.
            openMagicLink(url)

        case let .siteURLOnly(url):
            // §10.2: pre-fill the legacy site-address login screen with the URL
            // and auto-submit on entry so the merchant skips manual typing.
            let loginFields = LoginFields()
            loginFields.siteAddress = url.absoluteString
            loginFields.restrictToWPCom = false
            NavigateToEnterSite(loginFields: loginFields,
                                autoSubmitsPrefilledSiteAddress: true).execute(from: navigationController)
            finishIfDeepLink()

        case let .appLoginWPCom(siteURL, email):
            // §10.3 / §3.3: pre-fill the WP.com email + password screen.
            let loginFields = LoginFields()
            loginFields.siteAddress = siteURL
            loginFields.restrictToWPCom = true
            loginFields.username = email
            NavigateToEnterWPCOMPassword(loginFields: loginFields).execute(from: navigationController)
            finishIfDeepLink()

        case let .appLoginUsername(siteURL, username):
            // §10.3 / §3.3: pre-fill the wp-org site-credentials screen.
            let loginFields = LoginFields()
            loginFields.siteAddress = siteURL
            loginFields.restrictToWPCom = false
            loginFields.username = username
            NavigateToEnterSiteCredentials(loginFields: loginFields).execute(from: navigationController)
            finishIfDeepLink()

        case .installQR:
            // §10.4: the "install QR" is useless here — app is already installed.
            let error = QRLoginUserFacingError(kind: .installQR, phase: .prelude, primaryAction: .scanAgain)
            showErrorOnly(error)

        case .invalid:
            let error = QRLoginUserFacingError(kind: .invalidPayload, phase: .prelude, primaryAction: .scanAgain)
            showErrorOnly(error)
        }
    }

    /// Hands a magic-link URL to an `ASWebAuthenticationSession`.
    ///
    /// The session runs the wp.com page in an in-app Safari sheet and captures
    /// the `woocommerce://magic-login` callback itself — the merchant never
    /// leaves Woo for the external browser, and there is no "Open in app?"
    /// system prompt on the redirect back. The QR "signing in" screen stays
    /// visible underneath the sheet.
    ///
    /// On a captured callback the auth sheet is dismissed and the URL then runs
    /// through the existing `WordPressAuthenticator` handler — sign-in completes
    /// and the app swaps to the logged-in UI — and the coordinator finishes. If
    /// the merchant dismisses the sheet instead, `handleMagicLinkCancelled`
    /// unwinds the QR surface so they can retry.
    func openMagicLink(_ url: URL) {
        let window = navigationController.view.window
        let runner = QRLoginMagicLinkAuthRunner(
            anchor: window,
            onCallback: { [weak self] callbackURL in
                guard let rootViewController = window?.rootViewController else {
                    self?.finish()
                    return
                }
                // `WordPressAuthenticator.openAuthenticationURL` presents the
                // magic-link sign-in controller on whatever is topmost. The
                // ASWebAuthenticationSession sheet is still being torn down when
                // this callback fires, so handing the URL over right away would
                // present that controller on the dismissing sheet — it would
                // never reach the window and its navigation controller would
                // deallocate before the login epilogue runs, tripping the
                // `showLoginEpilogue` assertion. Dismiss the sheet first, then
                // hand off from the now-stable root.
                rootViewController.dismiss(animated: false) {
                    _ = WordPressAuthenticator.shared.handleWordPressAuthUrl(callbackURL,
                                                                             rootViewController: rootViewController)
                }
                // Sign-in proceeds through WordPressAuthenticator from here —
                // release the coordinator; the login UI is about to be replaced.
                self?.finish()
            },
            onCancel: { [weak self] in
                self?.handleMagicLinkCancelled()
            }
        )
        runner.start(url: url, callbackURLScheme: Bundle.main.dotcomAuthScheme)
    }

    func showHostView(with strategy: QRLoginStrategy) {
        let viewModel = QRLoginViewModel(strategy: strategy)
        let host = QRLoginHostView(
            viewModel: viewModel,
            onDone: { [weak self] in self?.handleSuccess() },
            onCancel: { [weak self] in self?.handleHostCancelled() },
            onScanAgain: { [weak self] in self?.handleScanAgain() },
            onEnterSiteURLTapped: { [weak self] in self?.handleEnterSiteURL() }
        )
        pushScreen(host)
    }

    /// Merchant cancelled from the number-match screen. In camera mode the
    /// merchant gets the scanner back; in deep-link mode there's no scanner to
    /// fall back to, so popping the host view exits the QR-login surface
    /// (spec §4.2 / §6.2).
    func handleHostCancelled() {
        navigationController.popViewController(animated: true)
        finishIfDeepLink()
    }

    /// Primary CTA on a non-retryable error ("Scan a new code", spec §6.1). In
    /// camera mode this returns the merchant to a *fresh* scanner — the
    /// previous scanner already consumed its payload and can't deliver again,
    /// so it is dropped from the stack rather than reused. In deep-link mode
    /// there's no scanner to return to, so the QR-login surface is dismissed
    /// (spec §4.2).
    func handleScanAgain() {
        analytics.trackClick(.qrStartOver)
        switch mode {
        case .camera:
            if let prologueViewController {
                navigationController.popToViewController(prologueViewController, animated: false)
            }
            presentScannerAfterCameraPermissionCheck()
        case .deepLink:
            navigationController.popViewController(animated: true)
            finish()
        }
    }

    // MARK: - Lifecycle

    /// The merchant backed out of the prologue — the QR-login surface is done.
    func handlePrologueBack() {
        navigationController.popViewController(animated: true)
        finish()
    }

    /// Routes the merchant to the legacy site-address login, pushed *on top* of
    /// the QR-login surface. The coordinator is deliberately kept alive: the QR
    /// screen underneath stays on the stack and is reachable by going back, so
    /// its controls must keep working. It is released later, when the QR screens
    /// are popped (`handlePrologueBack`) or replaced on a successful sign-in.
    func handleEnterSiteURL() {
        onEnterSiteURL()
    }

    /// Self-hosted sign-in completed — hand off to the store picker and end the
    /// QR-login flow.
    func handleSuccess() {
        onSuccess()
        finish()
    }

    /// The merchant dismissed the magic-link auth sheet without finishing
    /// sign-in. Unwind the QR surface so they can retry.
    ///
    /// In camera mode this unwinds to the prologue rather than the scanner: the
    /// scanner keeps the camera live (the merchant may still be pointing at a
    /// QR code, so it could capture another) and landing there re-enters the
    /// scan step. Deep-link mode has no prologue, so it pops the host view and
    /// exits the QR surface.
    func handleMagicLinkCancelled() {
        if let prologueViewController {
            navigationController.popToViewController(prologueViewController, animated: false)
        } else {
            navigationController.popViewController(animated: false)
        }
        finishIfDeepLink()
    }

    /// Fires `onFinished` exactly once so the owner can release this coordinator.
    func finish() {
        guard didFinish == false else { return }
        didFinish = true
        onFinished()
    }

    /// Releases the coordinator only in deep-link mode. After a camera-mode
    /// navigation the scanner and prologue stay on the stack, so the coordinator
    /// must stay alive to keep driving them when the merchant navigates back.
    func finishIfDeepLink() {
        if case .deepLink = mode {
            finish()
        }
    }

    func showErrorOnly(_ error: QRLoginUserFacingError) {
        analytics.trackStep(.qrError)
        analytics.trackFailure(QRLoginAnalyticsFailure.failureString(for: error))
        // `showErrorOnly` only ever carries a `.scanAgain` error (`.installQR`
        // / `.invalidPayload`), so the primary CTA always routes to a fresh
        // scanner.
        let view = QRLoginErrorView(
            error: error,
            onPrimaryTapped: { [weak self] in self?.handleScanAgain() },
            onEnterSiteURLTapped: { [weak self] in self?.handleEnterSiteURL() }
        )
        pushScreen(view)
    }
}

// MARK: - Navigation

private extension QRLoginCoordinator {
    /// Wraps `view` in a `QRLoginHostingController` and pushes it onto the login
    /// navigation stack, showing the navigation bar with a "Help" item by default.
    @discardableResult
    func pushScreen<Content: View>(_ view: Content,
                                   navigationBarStyle: QRLoginNavigationBarStyle = .inherited,
                                   prefersLightStatusBar: Bool = false,
                                   showsHelpButton: Bool = true) -> QRLoginHostingController<Content> {
        let hosting = QRLoginHostingController(rootView: view)
        hosting.navigationBarStyle = navigationBarStyle
        hosting.prefersLightStatusBar = prefersLightStatusBar
        if showsHelpButton {
            hosting.navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: Localization.help,
                primaryAction: UIAction { [weak self] _ in self?.showHelp() }
            )
        }
        navigationController.pushViewController(hosting, animated: true)
        return hosting
    }
}

// MARK: - Camera permission alerts (spec §4.1.1)

private extension QRLoginCoordinator {

    func showFirstDenialAlert() {
        let alert = UIAlertController(
            title: Localization.cameraFirstDenialTitle,
            message: Localization.cameraFirstDenialBody,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: Localization.cameraFirstDenialPrimary, style: .default) { [weak self] _ in
            self?.handleScanCTA() // re-request OS permission
        })
        alert.addAction(UIAlertAction(title: Localization.cancel, style: .cancel))
        navigationController.present(alert, animated: true)
    }

    func showPermanentlyDeniedAlert() {
        let alert = UIAlertController(
            title: Localization.cameraPermanentlyDeniedTitle,
            message: Localization.cameraPermanentlyDeniedBody,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: Localization.cameraPermanentlyDeniedPrimary, style: .default) { _ in
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url)
        })
        alert.addAction(UIAlertAction(title: Localization.cancel, style: .cancel))
        navigationController.present(alert, animated: true)
    }

    func showHelp() {
        analytics.trackClick(.showHelp)
        onShowHelp()
    }
}

// MARK: - Localization

private extension QRLoginCoordinator {
    enum Localization {
        static let help = NSLocalizedString(
            "qrLogin.help",
            value: "Help",
            comment: "Navigation-bar Help button on the QR-login screens."
        )
        static let cancel = NSLocalizedString(
            "qrLogin.cameraPermission.cancel",
            value: "Cancel",
            comment: "Cancel button on the camera-permission alerts."
        )
        static let cameraFirstDenialTitle = NSLocalizedString(
            "qrLogin.cameraPermission.firstDenial.title",
            value: "Camera access needed",
            comment: "Title of the alert shown the first time the user denies camera access."
        )
        static let cameraFirstDenialBody = NSLocalizedString(
            "qrLogin.cameraPermission.firstDenial.body",
            value: "Without camera access, you can still log in by entering your store address.",
            comment: "Body of the alert shown the first time the user denies camera access."
        )
        static let cameraFirstDenialPrimary = NSLocalizedString(
            "qrLogin.cameraPermission.firstDenial.primary",
            value: "Allow camera access",
            comment: "Primary action on the first-denial camera-permission alert."
        )
        static let cameraPermanentlyDeniedTitle = NSLocalizedString(
            "qrLogin.cameraPermission.permanentlyDenied.title",
            value: "Camera access is turned off",
            comment: "Title of the alert shown when the OS will no longer prompt for camera access."
        )
        static let cameraPermanentlyDeniedBody = NSLocalizedString(
            "qrLogin.cameraPermission.permanentlyDenied.body",
            value: "Enable camera access in Settings or cancel to sign in with your store address instead.",
            comment: "Body of the alert shown when the OS will no longer prompt for camera access."
        )
        static let cameraPermanentlyDeniedPrimary = NSLocalizedString(
            "qrLogin.cameraPermission.permanentlyDenied.primary",
            value: "Open Permissions Settings",
            comment: "Primary action on the permanently-denied camera-permission alert."
        )
    }
}

// MARK: - Magic-link auth session

/// Runs the wp.com QR magic-link handoff inside an `ASWebAuthenticationSession`.
///
/// `ASWebAuthenticationSession` opens the magic link in an in-app Safari sheet
/// and captures the `woocommerce://magic-login` callback itself — no external
/// browser, and no "Open in app?" system prompt on the redirect back.
///
/// The runner retains itself for the lifetime of the session and releases once
/// it ends — delivering the captured callback URL (`onCallback`), or signalling
/// cancellation (`onCancel`) if the merchant dismissed the sheet. The self-retain
/// decouples the session's lifetime from the `QRLoginCoordinator`.
@MainActor
private final class QRLoginMagicLinkAuthRunner: NSObject, ASWebAuthenticationPresentationContextProviding {

    private let anchor: ASPresentationAnchor?
    private let onCallback: @MainActor (URL) -> Void
    private let onCancel: @MainActor () -> Void
    private var session: ASWebAuthenticationSession?
    private var retainedSelf: QRLoginMagicLinkAuthRunner?

    init(anchor: ASPresentationAnchor?,
         onCallback: @escaping @MainActor (URL) -> Void,
         onCancel: @escaping @MainActor () -> Void) {
        self.anchor = anchor
        self.onCallback = onCallback
        self.onCancel = onCancel
    }

    /// Opens `url` in the auth session. `callbackURLScheme` is the custom scheme
    /// the wp.com page redirects to — the session ends the moment it sees it.
    func start(url: URL, callbackURLScheme: String) {
        retainedSelf = self
        let session = ASWebAuthenticationSession(url: url,
                                                 callbackURLScheme: callbackURLScheme) { [weak self] callbackURL, _ in
            Task { @MainActor in
                // Hold a strong reference before clearing the self-retain:
                // releasing `retainedSelf` first would deallocate the runner
                // mid-closure and the callbacks below would be dropped.
                guard let self else { return }
                self.retainedSelf = nil
                if let callbackURL {
                    self.onCallback(callbackURL)
                } else {
                    // A nil callbackURL means the merchant dismissed the sheet
                    // (or it failed) — hand back so the QR surface can recover.
                    self.onCancel()
                }
            }
        }
        // A magic link is self-authenticating, so the session needs no shared
        // Safari cookies — an ephemeral session also avoids the data-sharing
        // consent prompt.
        session.prefersEphemeralWebBrowserSession = true
        session.presentationContextProvider = self
        self.session = session
        session.start()
    }

    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            anchor ?? ASPresentationAnchor()
        }
    }
}
