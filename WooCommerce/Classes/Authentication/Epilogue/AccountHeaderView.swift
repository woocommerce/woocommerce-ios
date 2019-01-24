import Foundation
import UIKit



/// AccountHeaderView: Displays an Account's Details: [Gravatar + Name + Username]
///
class AccountHeaderView: UIView {

    /// Account's Gravatar.
    ///
    @IBOutlet private var gravatarImageView: UIImageView! {
        didSet {
            gravatarImageView.image = .gravatarPlaceholderImage
        }
    }

    /// Account's Full Name.
    ///
    @IBOutlet private var fullnameLabel: UILabel! {
        didSet {
            fullnameLabel.textColor = StyleManager.wooSecondary
        }
    }

    /// Account's Username.
    ///
    @IBOutlet private var usernameLabel: UILabel! {
        didSet {
            usernameLabel.textColor = StyleManager.wooGreyTextMin
        }
    }

    /// Help Button
    ///
    @IBOutlet private weak var helpButton: UIButton!

    // MARK: - Overridden Methods

    override func awakeFromNib() {
        super.awakeFromNib()
        setupHelpButton()
    }
}


// MARK: - Public Methods
//
extension AccountHeaderView {

    /// Account's Username.
    ///
    var username: String? {
        set {
            usernameLabel.text = newValue
        }
        get {
            return usernameLabel.text
        }
    }

    /// Account's Full Name
    ///
    var fullname: String? {
        set {
            fullnameLabel.text = newValue
        }
        get {
            return fullnameLabel.text
        }
    }

    /// Downloads (and displays) the Gravatar associated with the specified Email.
    ///
    func downloadGravatar(with email: String) {
        gravatarImageView.downloadGravatarWithEmail(email)
    }
}


// MARK: - Private Methods
//
private extension AccountHeaderView {

    func setupHelpButton() {
        let helpButtonTitle = NSLocalizedString("Help", comment: "Help button on store picker screen.")
        helpButton.setTitle(helpButtonTitle, for: .normal)
        helpButton.setTitle(helpButtonTitle, for: .highlighted)
        helpButton.setTitleColor(StyleManager.wooCommerceBrandColor, for: .normal)
        helpButton.setTitleColor(StyleManager.wooGreyMid, for: .highlighted)
        helpButton.on(.touchUpInside) { [weak self] control in
            self?.handleHelpButtonTapped(control)
        }
    }

    /// Handle the help button being tapped
    ///
    func handleHelpButtonTapped(_ sender: AnyObject) {
        //TODO: Imp the help on the picker screen
    }
}
