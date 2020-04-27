import UIKit

/// Contains a text field.
///
final class TextFieldTableViewCell: UITableViewCell {
    struct ViewModel {
        let text: String?
        let placeholder: String?
        let onTextChange: ((_ text: String?) -> Void)?
        let onTextDidBeginEditing: (() -> Void)?
        let inputFormatter: UnitInputFormatter?
    }

    @IBOutlet weak var textField: UITextField!

    private var viewModel: ViewModel?
    private var onTextChange: ((_ text: String?) -> Void)?
    private var onTextDidBeginEditing: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        configureTextField()
        applyDefaultBackgroundStyle()
        selectionStyle = .none
    }

    func configure(viewModel: ViewModel) {
        self.viewModel = viewModel
        onTextChange = viewModel.onTextChange
        onTextDidBeginEditing = viewModel.onTextDidBeginEditing

        textField.text = viewModel.text
        textField.placeholder = viewModel.placeholder
        textField.borderStyle = .none
        textField.addTarget(self, action: #selector(textFieldDidChange(textField:)), for: .editingChanged)
        textField.addTarget(self, action: #selector(textFieldDidBegin(textField:)), for: .editingDidBegin)
    }
}

private extension TextFieldTableViewCell {
    func configureTextField() {
        textField.clearButtonMode = .whileEditing
        textField.applyHeadlineStyle()
        textField.delegate = self
    }
}

private extension TextFieldTableViewCell {
    @objc func textFieldDidChange(textField: UITextField) {
        guard let formattedText = viewModel?.inputFormatter?.format(input: textField.text) else {
            onTextChange?(textField.text)
            return
        }
        textField.text = formattedText
        onTextChange?(formattedText)
    }

    @objc func textFieldDidBegin(textField: UITextField) {
        onTextDidBeginEditing?()
    }
}

extension TextFieldTableViewCell: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text,
            let textRange = Range(range, in: text) else {
                return false
        }
        let updatedText = text.replacingCharacters(in: textRange,
                                                   with: string)
        guard let isValid = viewModel?.inputFormatter?.isValid(input: updatedText) else {
            return true
        }
        return isValid == true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
