import UIKit


/// GravatarEmailTableViewCell: Gravatar image + Email address in a UITableViewCell.
/// - Note: Why not use a default-style UITableViewCell? Because it still uses springs and struts!
///
class GravatarEmailTableViewCell: UITableViewCell {

    /// Private properties
    ///
    @IBOutlet private weak var gravatarImageView: UIImageView?
    @IBOutlet private weak var emailLabel: UILabel?

    private let gridiconSize = CGSize(width: 48, height: 48)
    
    /// Public properties
    ///
    public static let reuseIdentifier = "GravatarEmailTableViewCell"

    public func configure(withEmail email: String?, andPlaceholder placeholderImage: UIImage? = nil) {
        
        gravatarImageView?.tintColor = WordPressAuthenticator.shared.unifiedStyle?.borderColor ?? WordPressAuthenticator.shared.style.primaryNormalBorderColor
        emailLabel?.textColor = WordPressAuthenticator.shared.unifiedStyle?.textSubtleColor ?? WordPressAuthenticator.shared.style.subheadlineColor
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

    /// Override methods
    ///
    public override func prepareForReuse() {
        emailLabel?.text = nil
        gravatarImageView?.image = nil
    }
    
}
