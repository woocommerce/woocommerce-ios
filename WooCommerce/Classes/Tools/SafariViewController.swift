import Foundation
import SafariServices


/// WooCommerce SafariViewController: Allows us to control the StatusBar Style
///
class SafariViewController: SFSafariViewController {

    /// Preserves the StatusBar Style present, prior to when this ViewController gets displayed.
    ///
    private var previousStatusBarStyle: UIStatusBarStyle?

    /// StatusBarStyle to be applied
    ///
    var statusBarStyle: UIStatusBarStyle = .default


    // MARK: - Overridden Properties and Methods

    /// Sets the status bar style to default (black)
    ///
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return statusBarStyle
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        previousStatusBarStyle = UIApplication.shared.statusBarStyle
        setNeedsStatusBarAppearanceUpdate()
    }

    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        setNeedsStatusBarAppearanceUpdate()
    }
}
