import SwiftUI
import UIKit

/// Hosting controller for the QR-login SwiftUI screens.
///
/// The WordPress-Authenticator prologue hides the navigation bar in its own
/// `viewWillAppear`, so each QR screen re-applies the navigation-bar state it
/// needs when it appears: the prologue and live-flow screens show the bar (for
/// the back button and the Help item), while the scanner keeps it hidden for
/// its full-bleed camera UI.
final class QRLoginHostingController<Content: View>: UIHostingController<Content> {
    /// When `false`, the navigation bar is hidden while this screen is visible.
    var showsNavigationBar = true

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(!showsNavigationBar, animated: animated)
    }
}
