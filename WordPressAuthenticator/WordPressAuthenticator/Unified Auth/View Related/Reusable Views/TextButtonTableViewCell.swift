import UIKit


/// TextButtonTableViewCell: a plain text button with default styles.
///
final class TextButtonTableViewCell: UITableViewCell {

    /// Private properties
    ///
    @IBOutlet private weak var button: UIButton!

    /// Public properties
    ///
    public static let reuseIdentifier = "TextButtonTableViewCell"

    public var buttonText: String? {
        get {
            return button.titleLabel?.text
        }
        set {
            button.setTitle(newValue, for: .normal)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        button.setTitleColor(WordPressAuthenticator.shared.unifiedStyle?.textButtonColor, for: .normal)
        button.setTitleColor(WordPressAuthenticator.shared.unifiedStyle?.textButtonHighlightColor, for: .highlighted)
    }
}
