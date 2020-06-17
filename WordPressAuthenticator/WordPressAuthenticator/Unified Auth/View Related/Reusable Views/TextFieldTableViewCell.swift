import UIKit


/// TextFieldTableViewCell: a textfield with a custom border line in a UITableViewCell.
///
class TextFieldTableViewCell: UITableViewCell {

    public static let reuseIdentifier = "TextFieldTableViewCell"

    @IBOutlet var borderView: UIView!
    @IBOutlet var textField: UITextField!

    override func awakeFromNib() {
        super.awakeFromNib()

        borderView.backgroundColor = WordPressAuthenticator.shared.unifiedStyle?.borderColor
    }
}
