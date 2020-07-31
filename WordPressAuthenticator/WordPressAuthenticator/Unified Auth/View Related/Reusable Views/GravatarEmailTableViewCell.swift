import UIKit


/// GravatarEmailTableViewCell: Gravatar image + Email address in a UITableViewCell.
/// - Note: Why not use a default-style UITableViewCell? Because it still uses springs and struts!
///
class GravatarEmailTableViewCell: UITableViewCell {

    /// Private properties
    ///
    @IBOutlet private weak var gravatarImageView: UIImageView?
    @IBOutlet private weak var label: UILabel!

    /// Public properties
    ///
    public static let reuseIdentifier = "GravatarEmailTableViewCell"

    override func awakeFromNib() {
        super.awakeFromNib()

        label.textColor = WordPressAuthenticator.shared.unifiedStyle?.textColor ?? WordPressAuthenticator.shared.style.instructionColor
        label.font = UIFont.preferredFont(forTextStyle: .body)
    }

    public func configureImage(_ image: UIImage?, text: String?) {
        gravatarImageView?.image = image
        label.text = text
    }

    /// Override methods
    ///
    public override func prepareForReuse() {
        label.text = nil
    }
}
