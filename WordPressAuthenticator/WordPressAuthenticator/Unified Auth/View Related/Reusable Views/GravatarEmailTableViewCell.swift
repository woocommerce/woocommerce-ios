import UIKit


/// GravatarEmailTableViewCell: Gravatar image + Email address in a UITableViewCell.
/// - Note: Why not use a default-style UITableViewCell? Because it still uses springs and struts!
///
class GravatarEmailTableViewCell: UITableViewCell {

    /// Private properties
    ///
    @IBOutlet private weak var gravatarImageView: UIImageView?
    @IBOutlet private weak var emailLabel: UILabel?

    /// Public properties
    ///
    public static let reuseIdentifier = "GravatarEmailTableViewCell"

    public func configureImage(_ image: UIImage?, text: String?) {
        gravatarImageView?.image = image
        gravatarImageView?.tintColor = WordPressAuthenticator.shared.unifiedStyle?.textColor ?? WordPressAuthenticator.shared.style.instructionColor
        emailLabel?.text = text
        emailLabel?.textColor = WordPressAuthenticator.shared.unifiedStyle?.textColor ?? WordPressAuthenticator.shared.style.instructionColor
        emailLabel?.font = UIFont.preferredFont(forTextStyle: .body)
    }

    /// Override methods
    ///
    public override func prepareForReuse() {
        emailLabel?.text = nil
    }
}
