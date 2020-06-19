import UIKit


/// TextFieldTableViewCell: a textfield with a custom border line in a UITableViewCell.
///
final class TextFieldTableViewCell: UITableViewCell {

    public static let reuseIdentifier = "TextFieldTableViewCell"

    private var hairlineBorderWidth: CGFloat {
        return 1.0 / UIScreen.main.scale
    }

    @IBOutlet private weak var borderView: UIView!
    @IBOutlet private weak var borderWidth: NSLayoutConstraint!
    @IBOutlet weak var textField: UITextField!

    override func awakeFromNib() {
        super.awakeFromNib()

        let borderColor = WordPressAuthenticator.shared.unifiedStyle?.borderColor ?? WordPressAuthenticator.shared.style.primaryNormalBorderColor
        borderView.backgroundColor = borderColor
        borderWidth.constant = hairlineBorderWidth
    }
}
