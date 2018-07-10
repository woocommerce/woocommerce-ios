import Foundation
import UIKit
import WordPressAuthenticator
import WordPressUI


/// Allows the user to pick which WordPress.com (OR) Jetpack-Connected-Store we should set up as the Main Store.
///
class StorePickerViewController: UIViewController {

    /// No Results Placeholder Image
    ///
    @IBOutlet private var noResultsImageView: UIImageView!

    /// No Results Placeholder Text
    ///
    @IBOutlet private var noResultsLabel: UILabel! {
        didSet {
            noResultsLabel.font = UIFont.font(forStyle: .subheadline, weight: .regular)
            noResultsLabel.textColor = StyleManager.wooGreyTextMin
        }
    }

    /// Header View: Displays all of the Account Details
    ///
    private let accountHeaderView: AccountHeaderView = {
        return AccountHeaderView.loadFromNib()
    }()

    /// Main tableView
    ///
    @IBOutlet private var tableView: UITableView! {
        didSet {
            tableView.tableHeaderView = accountHeaderView
        }
    }

    /// White-Background View, to be placed surrounding the bottom area.
    ///
    @IBOutlet private var actionBackgroundView: UIView! {
        didSet {
            actionBackgroundView.layer.masksToBounds = false
            actionBackgroundView.layer.shadowOpacity = Constants.backgroundShadowOpacity
        }
    }

    /// Default Action Button.
    ///
    @IBOutlet private var actionButton: UIButton! {
        didSet {
            actionButton.backgroundColor = .clear
        }
    }

    /// Closure to be executed upon dismissal.
    ///
    var onDismiss: (() -> Void)?



    // MARK: - Overriden Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        setup(mainView: view)
        setup(headerView: accountHeaderView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        onDismiss?()
    }
}


// MARK: - Initialization Methods
//
private extension StorePickerViewController {

    func setup(mainView: UIView) {
        mainView.backgroundColor = StyleManager.tableViewBackgroundColor
    }

    func setup(headerView: AccountHeaderView) {
        guard let defaultAccount = StoresManager.shared.sessionManager.defaultAccount else {
            return
        }

        headerView.username = "@" + defaultAccount.username
        headerView.fullname = defaultAccount.displayName
        headerView.downloadGravatar(with: defaultAccount.email)
    }
}


// MARK: - Action Handlers
//
extension StorePickerViewController {

    /// Proceeds with the Login Flow.
    ///
    @IBAction func continueWasPressed() {
        dismiss(animated: true, completion: nil)
    }
}


// MARK: - Nested Types
//
extension StorePickerViewController {

    struct Constants {
        static let backgroundShadowOpacity = Float(0.2)
    }
}
