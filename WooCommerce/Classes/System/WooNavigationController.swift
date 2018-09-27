import UIKit

/// Subclass to set Woo styling.
/// Use this when presenting modals.
///
class WooNavigationController: UINavigationController {

    /// Sets the status bar of the pushed view to white.
    ///
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return StyleManager.statusBarLight
    }
}
