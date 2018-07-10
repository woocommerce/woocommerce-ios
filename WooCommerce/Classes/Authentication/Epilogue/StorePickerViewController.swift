import Foundation
import UIKit
import WordPressAuthenticator
import WordPressUI


/// Allows the user to pick which WordPress.com (OR) Jetpack-Connected-Store we should set up as the Main Store.
///
class StorePickerViewController: UIViewController {

    /// White-Background View, to be placed surrounding the bottom area.
    ///
    @IBOutlet private var buttonBackgroundView: UIView! {
        didSet {
            buttonBackgroundView.layer.masksToBounds = false
            buttonBackgroundView.layer.shadowOpacity = Constants.backgroundShadowOpacity
        }
    }

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
    @IBOutlet private var usernameLabel: UILabel! {
        didSet {
            usernameLabel.textColor = StyleManager.wooGreyTextMin
        }
    }

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

    /// Default Action Button.
    ///
    @IBOutlet private var continueButton: UIButton! {
        didSet {
            continueButton.backgroundColor = .clear
        }
    }

    /// Closure to be executed upon dismissal.
    ///
    var onDismiss: (() -> Void)?



    // MARK: - Overriden Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        setupMainView()
        setupAccountDetails()
        downloadGravatarImage()
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

    func downloadGravatarImage() {
        guard let targetURL = StoresManager.shared.sessionManager.defaultAccount?.gravatarUrl, let gravatarURL = URL(string: targetURL) else  {
            return
        }

        gravatarImageView.downloadImage(from: gravatarURL, placeholderImage: .gravatarPlaceholderImage)
    }

    func setupAccountDetails() {
        guard let defaultAccount = StoresManager.shared.sessionManager.defaultAccount else {
            return
        }

        fullnameLabel.text = defaultAccount.displayName
        usernameLabel.text = "@" + defaultAccount.username
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
