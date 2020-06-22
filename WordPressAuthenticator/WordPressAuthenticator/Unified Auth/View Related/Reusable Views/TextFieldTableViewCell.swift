import UIKit


/// TextFieldTableViewCell: a textfield with a custom border line in a UITableViewCell.
///
class TextFieldTableViewCell: UITableViewCell {

    public static let reuseIdentifier = "TextFieldTableViewCell"

    private var hairlineBorderWidth: CGFloat {
        return 1.0 / UIScreen.main.scale
    }

    @IBOutlet var borderView: UIView!
    @IBOutlet var borderWidth: NSLayoutConstraint!
    @IBOutlet var textField: UITextField!

    override func awakeFromNib() {
        super.awakeFromNib()

        let borderColor = WordPressAuthenticator.shared.unifiedStyle?.borderColor ?? WordPressAuthenticator.shared.style.primaryNormalBorderColor
        borderView.backgroundColor = borderColor
        borderWidth.constant = hairlineBorderWidth
    }
}
