import UIKit


/// PlainTextButtonTableViewCell: a plain text button with default styles.
///
class PlainTextButtonTableViewCell: UITableViewCell {

    public static let reuseIdentifier = "PlainTextButtonTableViewCell"

    @IBOutlet private weak var button: UIButton!

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

        button.setTitleColor(WordPressAuthenticator.shared.unifiedStyle?.plainTextButtonColor, for: .normal)
        button.setTitleColor(WordPressAuthenticator.shared.unifiedStyle?.plainTextButtonHighlightColor, for: .highlighted)
    }
}
