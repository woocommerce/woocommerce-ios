import UIKit

/// Contains a title label and a text field.
///
final class TitleAndTextFieldTableViewCell: UITableViewCell {
    struct ViewModel {
        let title: String?
        let text: String?
        let placeholder: String?
        let state: State
        let onTextChange: ((_ text: String?) -> Void)?

        enum State {
            case normal
            case error
        }

        init(title: String?,
             text: String?,
             placeholder: String?,
             state: State = .normal,
             onTextChange: ((_ text: String?) -> Void)?) {
            self.title = title
            self.text = text
            self.placeholder = placeholder
            self.state = state
            self.onTextChange = onTextChange
        }
    }

    @IBOutlet private weak var contentStackView: UIStackView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var textField: UITextField!

    private var onTextChange: ((_ text: String?) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        configureSelectionStyle()
        configureTitleLabel()
        configureTextField()
        configureContentStackView()
        applyDefaultBackgroundStyle()
        configureTapGestureRecognizer()
    }

    func configure(viewModel: ViewModel) {
        titleLabel.text = viewModel.title
        titleLabel.textColor = viewModel.state.textColor
        textField.text = viewModel.text
        textField.placeholder = viewModel.placeholder
        textField.textColor = viewModel.state.textColor
        onTextChange = viewModel.onTextChange
    }

    func textFieldBecomeFirstResponder() {
        textField.becomeFirstResponder()
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
