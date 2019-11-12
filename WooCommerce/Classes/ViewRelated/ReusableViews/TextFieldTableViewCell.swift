import UIKit

final class TextFieldTableViewCell: UITableViewCell {
    @IBOutlet private weak var textField: UITextField!

    var isEditable: Bool {
        set {
            textField.isEnabled = newValue
        }

        get {
            return textField.isEnabled
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        configureTextField()
    }

    func updateText(_ text: String?, placeholder: String = "") {
        textField.text = text
        textField.placeholder = placeholder
    }
}

private extension TextFieldTableViewCell {
    func configureTextField() {
        textField.applyBodyStyle()
        textField.backgroundColor = .clear
        textField.borderStyle = .none
    }
}
