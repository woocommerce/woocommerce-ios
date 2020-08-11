import UIKit


/// SignupMagicLinkViewController: step two in the signup flow.
/// This VC prompts the user to open their email app to look for the magic link we sent.
///
final class SignupMagicLinkViewController: LoginViewController {

    // MARK: Properties

    @IBOutlet private weak var tableView: UITableView!
    private var rows = [Row]()

    var emailMagicLinkSource: EmailMagicLinkSource?
    override var sourceTag: WordPressSupportSourceTag {
        get {
            if let emailMagicLinkSource = emailMagicLinkSource,
                emailMagicLinkSource == .signup {
                return .wpComSignupMagicLink
            }
            return .loginMagicLink
        }
    }

    // MARK: - Actions
    @IBAction func handleContinueButtonTapped(_ sender: NUXButton) {

    }

    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        validationCheck()

        navigationItem.title = WordPressAuthenticator.shared.displayStrings.signUpTitle
        styleNavigationBar(forUnified: true)

        // Store default margin, and size table for the view.
        defaultTableViewMargin = tableViewLeadingConstraint?.constant ?? 0
        setTableViewMargins(forWidth: view.frame.width)

        localizePrimaryButton()
    }
}


// MARK: - Private Methods
private extension SignupMagicLinkViewController {
    /// Some last-minute gatekeeping.
    ///
    func validationCheck() {
        let email = loginFields.username
        if !email.isValidEmail() {
            assert(email.isValidEmail(), "The value of loginFields.username was not a valid email address.")
        }

        emailMagicLinkSource = loginFields.meta.emailMagicLinkSource
        assert(emailMagicLinkSource != nil, "Must have an email link source.")
    }

    // MARK: - Private Constants

    /// Rows listed in the order they were created.
    ///
    enum Row {
        case instructions

        var reuseIdentifier: String {
            switch self {
            case .instructions:
                return TextLabelTableViewCell.reuseIdentifier
            }
        }
    }
}
