import UIKit


/// GravatarEmailTableViewCell: Gravatar image + Email address in a UITableViewCell.
///
class GravatarEmailTableViewCell: UITableViewCell {

    /// Private properties
    ///
    @IBOutlet private weak var gravatarImageView: UIImageView?

    // The email field is a UITextField so we can listen for changes when using a password manager.
    // It is disabled so the user cannot edit it.
    // This results in the 1Password button being disabled as well.
    // So we add the 1Password button to a stack view instead of the email field.
    // When iOS12 support is removed, the emailStackView can be removed as it only facilitates 1Password.
    @IBOutlet private weak var emailLabel: UITextField!
    @IBOutlet private weak var emailStackView: UIStackView?
    
    private let gridiconSize = CGSize(width: 48, height: 48)
    
    /// Public properties
    ///
    public static let reuseIdentifier = "GravatarEmailTableViewCell"
    public var onePasswordHandler: ((_ sourceView: UITextField) -> Void)?
    public var onChangeSelectionHandler: ((_ sender: UITextField) -> Void)?
    
    /// Public Methods
    ///
    public func configure(withEmail email: String?, andPlaceholder placeholderImage: UIImage? = nil) {
        gravatarImageView?.tintColor = WordPressAuthenticator.shared.unifiedStyle?.borderColor ?? WordPressAuthenticator.shared.style.primaryNormalBorderColor
        emailLabel?.textColor = WordPressAuthenticator.shared.unifiedStyle?.textSubtleColor ?? WordPressAuthenticator.shared.style.subheadlineColor
        emailLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        emailLabel?.text = email

        setupOnePasswordButtonIfNeeded()
        
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
    
    // MARK: - 1Password

    /// Sets up a 1Password button if 1Password is available and user is on iOS 12.
    ///
    func setupOnePasswordButtonIfNeeded() {
        if #available(iOS 13, *) {
            // no-op, we rely on the key icon in the keyboard to initiate a password manager.
        } else {
            guard let emailStackView = emailStackView else {
                return
            }
            
            WPStyleGuide.configureOnePasswordButtonForStackView(emailStackView,
                                                                target: self,
                                                                selector: #selector(onePasswordTapped(_:)))
        }
    }
    
    @objc func onePasswordTapped(_ sender: UIButton) {
        onePasswordHandler?(emailLabel)
    }
    
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
        onChangeSelectionHandler?(emailLabel)
    }

}
