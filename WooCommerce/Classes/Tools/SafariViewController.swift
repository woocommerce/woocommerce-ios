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


    // MARK: - Overridden Methods

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        previousStatusBarStyle = UIApplication.shared.statusBarStyle
        UIApplication.shared.statusBarStyle = statusBarStyle
    }

    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        UIApplication.shared.statusBarStyle = previousStatusBarStyle ?? .lightContent
    }
}
