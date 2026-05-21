import AVFoundation
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
            onCancel: { [weak self] in self?.popScanner() },
            onHelpTapped: { [weak self] in self?.showHelp() }
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
            // §10.1: hand the URL to an in-app browser. WP.com redirects to
            // woocommerce://magic-login, picked up by the existing handler.
            openMagicLink(url)
            finish()

        case let .siteURLOnly(url):
            // §10.2: pre-fill the legacy site-address login screen with the URL
            // and auto-submit on entry so the merchant skips manual typing.
            let loginFields = LoginFields()
            loginFields.siteAddress = url.absoluteString
            loginFields.restrictToWPCom = false
            NavigateToEnterSite(loginFields: loginFields,
                                autoSubmitsPrefilledSiteAddress: true).execute(from: navigationController)
            finish()

        case let .appLoginWPCom(siteURL, email):
            // §10.3 / §3.3: pre-fill the WP.com email + password screen.
            let loginFields = LoginFields()
            loginFields.siteAddress = siteURL
            loginFields.restrictToWPCom = true
            loginFields.username = email
            NavigateToEnterWPCOMPassword(loginFields: loginFields).execute(from: navigationController)
            finish()

        case let .appLoginUsername(siteURL, username):
            // §10.3 / §3.3: pre-fill the wp-org site-credentials screen.
            let loginFields = LoginFields()
            loginFields.siteAddress = siteURL
            loginFields.restrictToWPCom = false
            loginFields.username = username
            NavigateToEnterSiteCredentials(loginFields: loginFields).execute(from: navigationController)
            finish()

        case .installQR:
            // §10.4: the "install QR" is useless here — app is already installed.
            let error = QRLoginUserFacingError(kind: .installQR, phase: .prelude, primaryAction: .scanAgain)
            showErrorOnly(error)

        case .invalid:
            let error = QRLoginUserFacingError(kind: .invalidPayload, phase: .prelude, primaryAction: .scanAgain)
            showErrorOnly(error)
        }
    }

    /// Opens a magic-link URL in an in-app browser. Presented from the
    /// navigation controller itself (not its top view controller) so the
    /// QR-login screen underneath can be safely popped after the handoff.
    func openMagicLink(_ url: URL) {
        WebviewHelper.launch(url, with: navigationController)
    }

    func showHostView(with strategy: QRLoginStrategy) {
        let viewModel = QRLoginViewModel(strategy: strategy)
        let host = QRLoginHostView(
            viewModel: viewModel,
            onDone: { [weak self] in self?.handleSuccess() },
            onMagicLinkHandedOff: { [weak self] in self?.handleMagicLinkHandedOff() },
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
        if case .deepLink = mode {
            finish()
        }
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

    /// Routes the merchant to the legacy site-address login and ends the
    /// QR-login flow.
    func handleEnterSiteURL() {
        onEnterSiteURL()
        finish()
    }

    /// Self-hosted sign-in completed — hand off to the store picker and end the
    /// QR-login flow.
    func handleSuccess() {
        onSuccess()
        finish()
    }

    /// The wp.com flow handed the magic link to an in-app browser. Sign-in
    /// completes via the magic-login redirect, so pop the host view (revealing
    /// the scanner / prologue if the merchant dismisses the browser) and end the
    /// QR-login flow — without routing to the store picker (spec §10.1).
    func handleMagicLinkHandedOff() {
        navigationController.popViewController(animated: false)
        finish()
    }

    /// Fires `onFinished` exactly once so the owner can release this coordinator.
    func finish() {
        guard didFinish == false else { return }
        didFinish = true
        onFinished()
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
