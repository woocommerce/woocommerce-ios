import UIKit


/// Part two of the self-hosted sign in flow: username + password. Used by WPiOS and NiOS.
/// A valid site address should be acquired before presenting this view controller.
///
class SiteCredentialsViewController: LoginViewController {

	/// Private properties.
    ///
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet var bottomContentConstraint: NSLayoutConstraint?

    // Required property declaration for `NUXKeyboardResponder` but unused here.
    var verticalCenterConstraint: NSLayoutConstraint?

    private var rows = [Row]()

    // MARK: - Actions
    @IBAction func handleContinueButtonTapped(_ sender: NUXButton) {

    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
}


// MARK: - Private Methods
private extension SiteCredentialsViewController {

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
