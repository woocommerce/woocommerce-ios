import UIKit


/// TextButtonTableViewCell: a plain text button with default styles.
///
class TextButtonTableViewCell: UITableViewCell {

    public static let reuseIdentifier = "TextButtonTableViewCell"

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
