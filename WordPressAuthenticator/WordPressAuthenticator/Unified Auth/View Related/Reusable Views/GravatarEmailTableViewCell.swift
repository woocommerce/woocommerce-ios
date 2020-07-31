import UIKit


/// GravatarEmailTableViewCell: Gravatar image + Email address in a UITableViewCell.
/// - Note: Why not use a default-style UITableViewCell? Because it still uses springs and struts!
///
class GravatarEmailTableViewCell: UITableViewCell {

    /// Private properties
    ///
    @IBOutlet private weak var gravatarImageView: UIImageView?
    @IBOutlet private weak var emailLabel: UILabel!

    /// Public properties
    ///
    public static let reuseIdentifier = "GravatarEmailTableViewCell"

    override func awakeFromNib() {
        super.awakeFromNib()

        emailLabel.textColor = WordPressAuthenticator.shared.unifiedStyle?.textColor ?? WordPressAuthenticator.shared.style.instructionColor
        emailLabel.font = UIFont.preferredFont(forTextStyle: .body)
    }

    public func configureImage(_ image: UIImage?, text: String?) {
        gravatarImageView?.image = image
        emailLabel.text = text
    }

    /// Override methods
    ///
    public override func prepareForReuse() {
        emailLabel.text = nil
    }
}
