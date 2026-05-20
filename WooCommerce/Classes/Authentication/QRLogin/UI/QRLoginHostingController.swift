import SwiftUI
import UIKit

/// Navigation-bar treatment for a QR-login screen.
enum QRLoginNavigationBarStyle {
    /// Bar hidden entirely — used by the full-bleed camera scanner and the dark
    /// prologue (which draws its own Back / Help controls).
    case hidden
    /// Inherit the navigation controller's existing bar — used by the light
    /// number-match and error screens.
    case inherited
}

/// Hosting controller for the QR-login SwiftUI screens.
///
/// The WordPress-Authenticator prologue hides the navigation bar in its own
/// `viewWillAppear`, so each QR screen re-applies the navigation-bar state it
/// needs when it appears.
final class QRLoginHostingController<Content: View>: UIHostingController<Content> {

    var navigationBarStyle: QRLoginNavigationBarStyle = .inherited

    /// When `true`, the status bar uses light content — for the dark prologue.
    var prefersLightStatusBar = false

    override var preferredStatusBarStyle: UIStatusBarStyle {
        prefersLightStatusBar ? .lightContent : .default
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        switch navigationBarStyle {
        case .hidden:
            navigationController?.setNavigationBarHidden(true, animated: animated)
        case .inherited:
            navigationController?.setNavigationBarHidden(false, animated: animated)
        }
        setNeedsStatusBarAppearanceUpdate()
    }
}
