import Foundation
import UIKit
import WordPressAuthenticator


/// Allows the user to pick which WordPress.com (OR) Jetpack-Connected-Store we should set up as the Main Store.
///
class StorePickerViewController: UIViewController {

    /// White-Background View, to be placed surrounding the bottom area.
    ///
    @IBOutlet private var backgroundView: UIView! {
        didSet {
            backgroundView.layer.masksToBounds = false
            backgroundView.layer.shadowOpacity = Constants.backgroundShadowOpacity
        }
    }

    /// Spinner, to be displayed while the User Details are being retrieved.
    ///
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!

    /// Account's Gravatar.
    ///
    @IBOutlet private var gravatarImageView: UIImageView! {
        didSet {
            gravatarImageView.image = .gravatarPlaceholderImage
        }
    }

    /// Account's Full Name.
    ///
    @IBOutlet private var fullnameLabel: UILabel!

    /// Account's Username.
    ///
    @IBOutlet private var usernameLabel: UILabel!

    /// Default Action Button.
    ///
    @IBOutlet private var continueButton: UIButton! {
        didSet {
            continueButton.backgroundColor = .clear
        }
    }

    ///
    ///
    var credentials: WordPressCredentials!

    /// Closure to be executed upon dismissal.
    ///
    var onDismiss: (() -> Void)?



    // MARK: - Overriden Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        setupMainView()
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

    func setupMainView() {
        view.backgroundColor = StyleManager.tableViewBackgroundColor
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
