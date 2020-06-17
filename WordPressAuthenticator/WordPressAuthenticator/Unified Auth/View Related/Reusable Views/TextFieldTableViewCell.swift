import UIKit


/// TextFieldTableViewCell: a textfield with a custom border line in a UITableViewCell.
///
class TextFieldTableViewCell: UITableViewCell {

    public static let reuseIdentifier = "TextFieldTableViewCell"

    @IBOutlet var borderView: UIView!
    @IBOutlet var textField: UITextField!

    override func awakeFromNib() {
        super.awakeFromNib()

        let borderColor = WordPressAuthenticator.shared.unifiedStyle?.borderColor ?? WordPressAuthenticator.shared.style.primaryNormalBorderColor
        borderView.backgroundColor = borderColor
    }
}
