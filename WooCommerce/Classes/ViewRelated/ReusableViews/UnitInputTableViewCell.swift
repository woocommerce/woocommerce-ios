import UIKit

struct UnitInputViewModel {
    enum UnitPosition {
        case afterInput
        case afterInputWithoutSpace
        case beforeInput
        case beforeInputWithoutSpace
        case none
    }

    let title: String
    let unit: String
    let value: String?
    let placeholder: String?
    let unitPosition: UnitPosition
    let keyboardType: UIKeyboardType
    let inputFormatter: UnitInputFormatter
    let onInputChange: ((_ input: String?) -> Void)?
}

/// Displays a title, an editable text field for user input and the unit of the text field value.
///
final class UnitInputTableViewCell: UITableViewCell {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var inputAndUnitStackView: UIStackView!
    @IBOutlet private weak var inputTextField: UITextField!
    @IBOutlet private weak var unitLabel: UILabel!

    private var inputFormatter: UnitInputFormatter?
    private var onInputChange: ((_ input: String?) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        configureSelectionStyle()
        configureTitleLabel()
        configureInputAndUnitStackView()
        configureInputTextField()
        configureUnitLabel()
        applyDefaultBackgroundStyle()
        configureTapGestureRecognizer()
    }

    func configure(viewModel: UnitInputViewModel) {
        titleLabel.text = viewModel.title
        unitLabel.text = viewModel.unit
        unitLabel.isHidden = viewModel.unit.isEmpty
        inputTextField.text = viewModel.value
        inputTextField.placeholder = viewModel.placeholder
        inputTextField.keyboardType = viewModel.keyboardType
        inputFormatter = viewModel.inputFormatter
        onInputChange = viewModel.onInputChange

        rearrangeInputAndUnitStackViewSubviews(using: viewModel.unitPosition)
    }
    
    func setAccessitibily(label: String, hint: String) {
        inputTextField.accessibilityLabel = ""
        inputTextField.accessibilityHint = ""
        self.accessibilityLabel = label
        self.accessibilityHint = hint
    }
}

// MARK: - UI Updates
//
private extension UnitInputTableViewCell {
    func rearrangeInputAndUnitStackViewSubviews(using position: UnitInputViewModel.UnitPosition) {
        inputAndUnitStackView.removeAllArrangedSubviews()

        switch position {
        case .beforeInput, .beforeInputWithoutSpace:
            inputAndUnitStackView.addArrangedSubviews([unitLabel, inputTextField])
        case .afterInput, .afterInputWithoutSpace:
            inputAndUnitStackView.addArrangedSubviews([inputTextField, unitLabel])
        case .none:
            inputAndUnitStackView.addArrangedSubviews([inputTextField])
        }

        switch position {
        case .beforeInput, .afterInput:
            inputAndUnitStackView.spacing = Constants.stackViewSpacing
        case .afterInputWithoutSpace, .beforeInputWithoutSpace:
            inputAndUnitStackView.spacing = 0
        default:
            break
        }
    }
}

// MARK: - Configurations
//
private extension UnitInputTableViewCell {
    func configureSelectionStyle() {
        selectionStyle = .none
    }

    func configureTitleLabel() {
        titleLabel.applyBodyStyle()
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    func configureInputAndUnitStackView() {
        inputAndUnitStackView.spacing = Constants.stackViewSpacing
        inputAndUnitStackView.distribution = .fill
    }

    func configureInputTextField() {
        inputTextField.borderStyle = .none
        inputTextField.applyBodyStyle()
        if traitCollection.layoutDirection == .rightToLeft {
            // swiftlint:disable:next natural_text_alignment
            inputTextField.textAlignment = .left
            // swiftlint:enable:next natural_text_alignment
        } else {
            // swiftlint:disable:next inverse_text_alignment
            inputTextField.textAlignment = .right
            // swiftlint:enable:next inverse_text_alignment
        }
        inputTextField.delegate = self
        inputTextField.addTarget(self, action: #selector(textFieldDidChange(textField:)), for: .editingChanged)

        inputTextField.setContentHuggingPriority(.required, for: .horizontal)

        // If auto font size adjustment is enabled, the text field does not know the appropriate width and the font size shrinks even though space is available.
        inputTextField.adjustsFontSizeToFitWidth = false
    }

    func configureUnitLabel() {
        unitLabel.applyBodyStyle()
        unitLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        unitLabel.setContentHuggingPriority(.required, for: .horizontal)
    }

    func configureTapGestureRecognizer() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cellTapped))
        tapGesture.cancelsTouchesInView = false
        addGestureRecognizer(tapGesture)
    }
}

private extension UnitInputTableViewCell {
    /// When the cell is tapped, the text field become the first responder
    ///
    @objc func cellTapped(sender: UIView) {
        inputTextField.becomeFirstResponder()
    }
}

extension UnitInputTableViewCell: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text,
            let textRange = Range(range, in: text) else {
                                                        return false
        }
        let updatedText = text.replacingCharacters(in: textRange,
                                                   with: string)
        return inputFormatter?.isValid(input: updatedText) == true
    }
}

private extension UnitInputTableViewCell {
    @objc func textFieldDidChange(textField: UITextField) {
        let formattedText = inputFormatter?.format(input: textField.text)
        textField.text = inputFormatter?.format(input: formattedText)
        onInputChange?(formattedText)
    }
}

private extension UnitInputTableViewCell {
    enum Constants {
        static let stackViewSpacing: CGFloat = 6
    }
}
