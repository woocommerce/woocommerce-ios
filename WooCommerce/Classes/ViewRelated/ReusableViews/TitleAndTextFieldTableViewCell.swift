import UIKit

/// Contains a title label and a text field.
///
final class TitleAndTextFieldTableViewCell: UITableViewCell {
    struct ViewModel {
        let title: String?
        let text: String?
        let placeholder: String?
        let state: State
        let keyboardType: UIKeyboardType
        let textFieldAlignment: TextFieldTextAlignment
        let inputView: UIView?
        let inputAccessoryView: UIView?
        let onTextChange: ((_ text: String?) -> Void)?
        let onEditingEnd: (() -> Void)?

        enum State {
            case normal
            case error
        }

        init(title: String?,
             text: String?,
             placeholder: String?,
             state: State = .normal,
             keyboardType: UIKeyboardType = .default,
             textFieldAlignment: TextFieldTextAlignment,
             inputView: UIView? = nil,
             inputAccessoryView: UIView? = nil,
             onTextChange: ((_ text: String?) -> Void)? = nil,
             onEditingEnd: (() -> Void)? = nil) {
            self.title = title
            self.text = text
            self.placeholder = placeholder
            self.state = state
            self.keyboardType = keyboardType
            self.textFieldAlignment = textFieldAlignment
            self.inputView = inputView
            self.inputAccessoryView = inputAccessoryView
            self.onTextChange = onTextChange
            self.onEditingEnd = onEditingEnd
        }
    }

    @IBOutlet private weak var contentStackView: UIStackView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var textField: UITextField!

    private var onTextChange: ((_ text: String?) -> Void)?
    private var onEditingEnd: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        configureSelectionStyle()
        configureTitleLabel()
        configureTextField()
        configureContentStackView()
        configureDefaultBackgroundConfiguration()
        configureTapGestureRecognizer()
    }

    func configure(viewModel: ViewModel, textFieldEnabled: Bool = true) {
        titleLabel.text = viewModel.title
        titleLabel.textColor = viewModel.state.textColor
        textField.text = viewModel.text
        textField.placeholder = viewModel.placeholder
        textField.textColor = viewModel.state.textColor
        textField.keyboardType = viewModel.keyboardType
        textField.textAlignment = viewModel.textFieldAlignment.toTextAlignment()
        textField.isEnabled = textFieldEnabled
        textField.inputView = viewModel.inputView
        textField.inputAccessoryView = viewModel.inputAccessoryView
        onTextChange = viewModel.onTextChange
        onEditingEnd = viewModel.onEditingEnd
    }

    func textFieldBecomeFirstResponder() {
        textField.becomeFirstResponder()
    }

    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        updateDefaultBackgroundConfiguration(using: state)
    }
}

private extension TitleAndTextFieldTableViewCell {
    func configureSelectionStyle() {
        selectionStyle = .none
    }

    func configureTitleLabel() {
        titleLabel.applyBodyStyle()
    }

    func configureTextField() {
        textField.applyBodyStyle()
        textField.borderStyle = .none
        textField.addTarget(self, action: #selector(textFieldDidChange(textField:)), for: .editingChanged)
        textField.addTarget(self, action: #selector(textFieldDidResignFirstResponder(textField:)), for: .editingDidEnd)
    }

    func configureContentStackView() {
        contentStackView.spacing = 30
    }

    func configureTapGestureRecognizer() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cellTapped))
        tapGesture.cancelsTouchesInView = false
        addGestureRecognizer(tapGesture)
    }
}

private extension TitleAndTextFieldTableViewCell {
    /// When the cell is tapped, the text field become the first responder
    ///
    @objc func cellTapped(sender: UIView) {
        textField.becomeFirstResponder()
    }
}


private extension TitleAndTextFieldTableViewCell {
    @objc func textFieldDidChange(textField: UITextField) {
        onTextChange?(textField.text)
    }

    @objc func textFieldDidResignFirstResponder(textField: UITextField) {
        onEditingEnd?()
    }
}

private extension TitleAndTextFieldTableViewCell.ViewModel.State {
    var textColor: UIColor {
        switch self {
        case .normal:
            return .text
        case .error:
            return .error
        }
    }
}
