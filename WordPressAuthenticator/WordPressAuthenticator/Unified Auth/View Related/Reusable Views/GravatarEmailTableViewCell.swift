import UIKit

/// GravatarEmailTableViewCell: Gravatar image + Email address in a UITableViewCell.
///
class GravatarEmailTableViewCell: UITableViewCell {

    /// Private properties
    ///
    @IBOutlet private weak var gravatarImageView: UIImageView?
    @IBOutlet private weak var emailLabel: UITextField?

    private let gridiconSize = CGSize(width: 48, height: 48)

    /// Public properties
    ///
    public static let reuseIdentifier = "GravatarEmailTableViewCell"
    public var onChangeSelectionHandler: ((_ sender: UITextField) -> Void)?

    /// Public Methods
    ///
    public func configure(withEmail email: String?, andPlaceholder placeholderImage: UIImage? = nil) {
        gravatarImageView?.tintColor = WordPressAuthenticator.shared.unifiedStyle?.borderColor ?? WordPressAuthenticator.shared.style.primaryNormalBorderColor
        emailLabel?.textColor = WordPressAuthenticator.shared.unifiedStyle?.textColor ?? WordPressAuthenticator.shared.style.instructionColor
        emailLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        emailLabel?.text = email

        let gridicon = UIImage.gridicon(.userCircle, size: gridiconSize)

        guard let email = email,
            email.isValidEmail() else {
                gravatarImageView?.image = gridicon
                return
        }

        gravatarImageView?.downloadGravatarWithEmail(email, placeholderImage: placeholderImage ?? gridicon)
    }

    func updateEmailAddress(_ email: String?) {
        emailLabel?.text = email
    }

}

// MARK: - Password Manager Handling

private extension GravatarEmailTableViewCell {

    // MARK: - All Password Managers

    /// Call the handler when the text field changes.
    ///
    /// - Note: we have to manually add an action to the textfield
    /// because the delegate method `textFieldDidChangeSelection(_ textField: UITextField)`
    /// is only available to iOS 13+. When we no longer support iOS 12,
    /// `textFieldDidChangeSelection`, and `onChangeSelectionHandler` can
    /// be deleted in favor of adding the delegate method to view controllers.
    ///
    @IBAction func textFieldDidChangeSelection() {
        guard let emailTextField = emailLabel else {
            return
        }

        onChangeSelectionHandler?(emailTextField)
    }

}
