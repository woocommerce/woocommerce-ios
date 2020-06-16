import UIKit


/// TextFieldTableViewCell: a textfield with a custom border line in a UITableViewCell.
///
class TextFieldTableViewCell: UITableViewCell {

    public static let reuseIdentifier = "TextFieldTableViewCell"

    @IBOutlet var borderView: UIView!
    @IBOutlet var textField: UITextField!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
