import UIKit

/// Contains a text field.
///
final class TextFieldTableViewCell: UITableViewCell {
    struct ViewModel {
        let text: String?
        let placeholder: String?
        let onTextChange: ((_ text: String?) -> Void)?
    }

    @IBOutlet private weak var textField: UITextField!

    private var onTextChange: ((_ text: String?) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        configureTextField()
        applyDefaultBackgroundStyle()
    }

    func configure(viewModel: ViewModel) {
        onTextChange = viewModel.onTextChange

        textField.text = viewModel.text
        textField.placeholder = viewModel.placeholder
        textField.borderStyle = .none
        textField.addTarget(self, action: #selector(textFieldDidChange(textField:)), for: .editingChanged)
    }
}

private extension TextFieldTableViewCell {
    func configureTextField() {
        textField.clearButtonMode = .whileEditing
        textField.applyHeadlineStyle()
    }
}

private extension TextFieldTableViewCell {
    @objc func textFieldDidChange(textField: UITextField) {
        onTextChange?(textField.text)
    }
}
