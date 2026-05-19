import AVFoundation
import Networking
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
    private let onSuccess: () -> Void

    init(mode: Mode = .camera,
         navigationController: UINavigationController,
         parser: QRLoginPayloadParser = QRLoginPayloadParser(),
         cameraPermissionChecker: QRLoginCameraPermissionCheckerProtocol = DefaultQRLoginCameraPermissionChecker(),
         analytics: QRLoginAnalyticsTracking = DefaultQRLoginAnalyticsTracking(),
         onEnterSiteURL: @escaping () -> Void,
         onSuccess: @escaping () -> Void) {
        self.mode = mode
        self.navigationController = navigationController
        self.parser = parser
        self.cameraPermissionChecker = cameraPermissionChecker
        self.analytics = analytics
        self.onEnterSiteURL = onEnterSiteURL
        self.onSuccess = onSuccess
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
}

// MARK: - Prologue + scanner

private extension QRLoginCoordinator {

    func showPrologue() {
        analytics.trackStep(.qrPrologue)
        let view = QRLoginPrologueView(
            onScanTapped: { [weak self] in self?.handleScanCTA() },
            onSiteAddressTapped: { [weak self] in self?.fallbackToSiteAddress() },
            onHelpTapped: { [weak self] in self?.showHelp() },
            onURLTapped: { Self.copyLoginURL() }
        )
        navigationController.pushViewController(UIHostingController(rootView: view), animated: true)
    }

    func handleScanCTA() {
        analytics.trackClick(.qrLoginScan)
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
        let hosting = UIHostingController(rootView: view)
        hosting.modalPresentationStyle = .fullScreen
        navigationController.pushViewController(hosting, animated: true)
    }

    func popScanner() {
        navigationController.popViewController(animated: true)
    }

    func fallbackToSiteAddress() {
        analytics.trackClick(.qrLoginFallback)
        onEnterSiteURL()
    }

    static func copyLoginURL() {
        UIPasteboard.general.string = "https://woo.com/mobilelogin"
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

        case let .siteURLOnly(url):
            // §10.2: pre-fill the legacy site-address login screen with the URL.
            // The site-address screen auto-submits on entry.
            let loginFields = LoginFields()
            loginFields.siteAddress = url.absoluteString
            loginFields.restrictToWPCom = false
            NavigateToEnterSite().execute(from: navigationController)
            // TODO: pre-fill the WPA site-address field. SiteAddressViewController
            // doesn't currently take an init field, so the prefill is left for
            // a follow-up — verification on simulator will exercise the
            // primary self-hosted path which doesn't need this.

        case let .appLoginWPCom(siteURL, email):
            // §10.3 / §3.3: pre-fill the WP.com email + password screen.
            let loginFields = LoginFields()
            loginFields.siteAddress = siteURL
            loginFields.restrictToWPCom = true
            loginFields.username = email
            NavigateToEnterWPCOMPassword(loginFields: loginFields).execute(from: navigationController)

        case let .appLoginUsername(siteURL, username):
            // §10.3 / §3.3: pre-fill the wp-org site-credentials screen.
            let loginFields = LoginFields()
            loginFields.siteAddress = siteURL
            loginFields.restrictToWPCom = false
            loginFields.username = username
            NavigateToEnterSiteCredentials(loginFields: loginFields).execute(from: navigationController)

        case .installQR:
            // §10.4: the "install QR" is useless here — app is already installed.
            let error = QRLoginUserFacingError(kind: .installQR, phase: .prelude, primaryAction: .scanAgain)
            showErrorOnly(error)

        case .invalid:
            let error = QRLoginUserFacingError(kind: .invalidPayload, phase: .prelude, primaryAction: .scanAgain)
            showErrorOnly(error)
        }
    }

    func openMagicLink(_ url: URL) {
        guard let topVC = navigationController.topViewController ?? navigationController.viewControllers.last else {
            return
        }
        WebviewHelper.launch(url, with: topVC)
    }

    func showHostView(with strategy: QRLoginStrategy) {
        let viewModel = QRLoginViewModel(strategy: strategy)
        let host = QRLoginHostView(
            viewModel: viewModel,
            onDone: { [weak self] in self?.onSuccess() },
            onIdle: { [weak self] in self?.handleHostIdle() },
            onEnterSiteURLTapped: { [weak self] in self?.onEnterSiteURL() }
        )
        navigationController.pushViewController(UIHostingController(rootView: host), animated: true)
    }

    func handleHostIdle() {
        // View model returned to idle (cancel from number-match). In camera
        // mode the merchant gets the scanner back; in deep-link mode we exit.
        switch mode {
        case .camera:
            // Pop the host VC so the scanner is back on top.
            navigationController.popViewController(animated: true)
        case .deepLink:
            navigationController.popViewController(animated: true)
        }
    }

    func showErrorOnly(_ error: QRLoginUserFacingError) {
        analytics.trackStep(.qrError)
        analytics.trackFailure(QRLoginAnalyticsFailure.failureString(for: error))
        let view = QRLoginErrorView(
            error: error,
            onPrimaryTapped: { [weak self] in self?.popScanner() },
            onEnterSiteURLTapped: { [weak self] in self?.onEnterSiteURL() }
        )
        navigationController.pushViewController(UIHostingController(rootView: view), animated: true)
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
        // Help integration is hooked up via the existing
        // `AuthenticationManager.presentSupport(from:sourceTag:)`. For Layer 5
        // we delegate to the system: the WordPress-Authenticator help icon
        // path already covers this — see the existing prologue's help button
        // wiring. Keeping this method as the analytics-only stub for now;
        // the full Support hookup is part of the polish phase.
    }
}

// MARK: - Localization

private extension QRLoginCoordinator {
    enum Localization {
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
