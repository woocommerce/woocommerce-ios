import UIKit

/// Contains a text field.
///
final class TextFieldTableViewCell: UITableViewCell {
    struct ViewModel {
        internal init(text: String? = nil, placeholder: String? = nil, onTextChange: ((String?) -> Void)? = nil,
                      onTextDidBeginEditing: (() -> Void)? = nil, onTextDidReturn: ((String?) -> Void)? = nil,
                      inputFormatter: UnitInputFormatter? = nil, keyboardType: UIKeyboardType,
                      returnKeyType: UIReturnKeyType = .default, autocapitalizationType: UITextAutocapitalizationType = .none) {
            self.text = text
            self.placeholder = placeholder
            self.onTextChange = onTextChange
            self.onTextDidBeginEditing = onTextDidBeginEditing
            self.onTextDidReturn = onTextDidReturn
            self.inputFormatter = inputFormatter
            self.keyboardType = keyboardType
            self.returnKeyType = returnKeyType
            self.autocapitalizationType = autocapitalizationType
        }
        let text: String?
        let placeholder: String?
        let onTextChange: ((_ text: String?) -> Void)?
        let onTextDidBeginEditing: (() -> Void)?
        let onTextDidReturn: ((_ text: String?) -> Void)?
        let inputFormatter: UnitInputFormatter?
        let keyboardType: UIKeyboardType
        let returnKeyType: UIReturnKeyType
        let autocapitalizationType: UITextAutocapitalizationType
    }

    @IBOutlet private weak var textField: UITextField!

    private var viewModel: ViewModel?
    private var onTextChange: ((_ text: String?) -> Void)?
    private var onTextDidBeginEditing: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        configureTextField()
        applyDefaultBackgroundStyle()
        applyStyle(style: .headline)
        selectionStyle = .none
    }

    func configure(viewModel: ViewModel) {
        self.viewModel = viewModel
        onTextChange = viewModel.onTextChange
        onTextDidBeginEditing = viewModel.onTextDidBeginEditing

        textField.text = viewModel.text
        textField.placeholder = viewModel.placeholder
        textField.borderStyle = .none
        textField.keyboardType = viewModel.keyboardType
        textField.returnKeyType = viewModel.returnKeyType
        textField.addTarget(self, action: #selector(textFieldDidChange(textField:)), for: .editingChanged)
        textField.addTarget(self, action: #selector(textFieldDidBegin(textField:)), for: .editingDidBegin)
        textField.autocapitalizationType = viewModel.autocapitalizationType
    }

    @discardableResult
    override func becomeFirstResponder() -> Bool {
        textField.becomeFirstResponder()
    }

    @discardableResult
    override func resignFirstResponder() -> Bool {
        textField.resignFirstResponder()
    }
}

private extension TextFieldTableViewCell {
    func configureTextField() {
        textField.clearButtonMode = .whileEditing
        textField.delegate = self
    }
}

// Styles
extension TextFieldTableViewCell {

    enum Style {
        case body
        case headline
    }

    func applyStyle(style: Style) {
        switch style {
        case .headline:
            textField.applyHeadlineStyle()
        case .body:
            textField.applyBodyStyle()
        }
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
        guard let inputFormatter = viewModel?.inputFormatter else {
            return true
        }
        return inputFormatter.isValid(input: updatedText)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        viewModel?.onTextDidReturn?(textField.text)
        textField.resignFirstResponder()
        return true
    }
}
