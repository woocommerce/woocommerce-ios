import UIKit
import WordPressShared

/// Handles the final step in the magic link auth process. At this point all the
/// necessary auth work should be done. We just need to create a WPAccount and to
/// sync account info and blog details.
/// The expectation is this controller will be momentarily visible when the app
/// is resumed/launched via the appropriate custom scheme, and quickly dismiss.
///
class NUXLinkAuthViewController: LoginViewController {
    @IBOutlet weak var statusLabel: UILabel?

    /// Displays the specified text in the status label.
    ///
    /// - Parameter message: The text to display in the label.
    ///
    override func configureStatusLabel(_ message: String) {
        statusLabel?.text = message
    }
}
