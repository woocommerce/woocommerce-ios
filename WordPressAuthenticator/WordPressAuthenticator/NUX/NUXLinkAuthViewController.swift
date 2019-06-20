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
    @objc var token: String = ""
    @objc var didSync: Bool = false

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Gotta have a token to use this vc
        assert(!token.isEmpty, "Email token cannot be nil")

        if didSync {
            return
        }

        didSync = true // Make sure we don't call this twice by accident

        let wpcom = WordPressComCredentials(authToken: token, isJetpackLogin: isJetpackLogin, multifactor: false, siteURL: loginFields.siteAddress)
        let credentials = AuthenticatorCredentials(wpcom: wpcom)
        syncWPComAndPresentEpilogue(credentials: credentials)

        // Count this as success since we're authed. Even if there is a glitch
        // while syncing the user has valid credentials.
        if let linkSource = loginFields.meta.emailMagicLinkSource {
            switch linkSource {
            case .signup:
                // This stat is part of a funnel that provides critical information.  Before
                // making ANY modification to this stat please refer to: p4qSXL-35X-p2
                WordPressAuthenticator.track(.createdAccount, properties: ["source": "email"])
                WordPressAuthenticator.track(.signupMagicLinkSucceeded)
            case .login:
                WordPressAuthenticator.track(.loginMagicLinkSucceeded)
            }
        }
    }

    /// Displays the specified text in the status label.
    ///
    /// - Parameter message: The text to display in the label.
    ///
    override func configureStatusLabel(_ message: String) {
        statusLabel?.text = message
    }

    override func updateSafariCredentialsIfNeeded() {
        // Noop
    }
}
