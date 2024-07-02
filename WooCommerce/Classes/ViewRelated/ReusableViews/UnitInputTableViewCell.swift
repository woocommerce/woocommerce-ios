import UIKit

struct UnitInputViewModel {
    enum UnitPosition {
        case afterInput
        case afterInputWithoutSpace
        case beforeInput
        case beforeInputWithoutSpace
        case none
    }

    enum Style {
        /// The default style with a title label in the left and the price input textfield in the right.
        case primary
        /// A style with the price input textfield in the left, it does not support title text.
        case secondary
    }

    let title: String
    var subtitle: String? = nil
    let unit: String
    let value: String?
    let placeholder: String?
    let accessibilityHint: String?
    let unitPosition: UnitPosition
    let keyboardType: UIKeyboardType
    let inputFormatter: UnitInputFormatter
    let style: Style
    var isInputEnabled: Bool = true
    let onInputChange: ((_ input: String?) -> Void)?
}

/// Displays a title, an editable text field for user input and the unit of the text field value.
///
final class UnitInputTableViewCell: UITableViewCell {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var inputAndUnitStackView: UIStackView!
    @IBOutlet private weak var inputTextField: UITextField!
    @IBOutlet private weak var unitLabel: UILabel!
    @IBOutlet private weak var inputAndUnitStackViewToTitleLabel: NSLayoutConstraint!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var subtitleLabelToInputAndUnitStackView: NSLayoutConstraint!

    private var inputFormatter: UnitInputFormatter?
    private var onInputChange: ((_ input: String?) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        configureSelectionStyle()
        configureTitleLabel()
        configureSubtitleLabel()
        configureInputAndUnitStackView()
        configureInputTextField()
        configureUnitLabel()
        configureDefaultBackgroundConfiguration()
        configureTapGestureRecognizer()
    }

    func configure(viewModel: UnitInputViewModel) {
        titleLabel.text = viewModel.title
        subtitleLabel.text = viewModel.subtitle
        subtitleLabelToInputAndUnitStackView.constant = viewModel.subtitle == nil ? 0 : Constants.subtitleLabelToInputAndUnitStackViewSpacing
        unitLabel.text = viewModel.unit
        unitLabel.isHidden = viewModel.unit.isEmpty
        inputTextField.text = viewModel.value
        inputTextField.placeholder = viewModel.placeholder
        inputTextField.keyboardType = viewModel.keyboardType
        accessibilityHint = viewModel.accessibilityHint
        inputFormatter = viewModel.inputFormatter
        onInputChange = viewModel.onInputChange

        configureStyle(viewModel.style)
        configureInputTextFieldState(enabled: viewModel.isInputEnabled)

        rearrangeInputAndUnitStackViewSubviews(using: viewModel.unitPosition)
    }

    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        updateDefaultBackgroundConfiguration(using: state)
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

    func configureSubtitleLabel() {
        subtitleLabel.applyFootnoteStyle()
        subtitleLabel.numberOfLines = 0
    }

    func configureInputAndUnitStackView() {
        inputAndUnitStackView.spacing = Constants.stackViewSpacing
        inputAndUnitStackView.distribution = .fill
    }

    func configureInputTextField() {
        inputTextField.borderStyle = .none
        inputTextField.applyBodyStyle()

        inputTextField.delegate = self
        inputTextField.addTarget(self, action: #selector(textFieldDidChange(textField:)), for: .editingChanged)

        // If auto font size adjustment is enabled, the text field does not know the appropriate width and the font size shrinks even though space is available.
        inputTextField.adjustsFontSizeToFitWidth = false
    }

    func configureInputTextFieldState(enabled: Bool) {
        inputTextField.isEnabled = enabled
        enabled ? inputTextField.applyBodyStyle() : inputTextField.applySecondaryBodyStyle()
    }

    private func configureStyle(_ style: UnitInputViewModel.Style) {

        if style == .primary {
            inputAndUnitStackViewToTitleLabel.constant = Constants.inputAndUnitStackViewToTitleLabelSpacing
            inputTextField.setContentHuggingPriority(.required, for: .horizontal)
        } else {
            // In secondary style we have no title do we need to remove the extra space between
            // the title and the stackView
            inputAndUnitStackViewToTitleLabel.constant = 0.0
            // If the title label has higher hugging priority then this textfield will stretch take all the free space
            inputTextField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        }

        if traitCollection.layoutDirection == .rightToLeft {
            // swiftlint:disable:next inverse_text_alignment
            inputTextField.textAlignment = style == .primary ? .left : .right
            // swiftlint:enable:next natural_text_alignment
        } else {
            // swiftlint:disable:next inverse_text_alignment
            inputTextField.textAlignment = style == .primary ? .right : .left
            // swiftlint:enable:next inverse_text_alignment
        }
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
        static let inputAndUnitStackViewToTitleLabelSpacing: CGFloat = 16
        static let subtitleLabelToInputAndUnitStackViewSpacing: CGFloat = 8
    }
}

// MARK: - Accessibility config
//
extension UnitInputTableViewCell {

    /// Make this the accessibile element. Do not allow text field to be accessible right away.
    override  var isAccessibilityElement: Bool {
        get {
            true
        }
        set { }
    }

    override var accessibilityLabel: String? {
        get {
            titleLabel.text
        }
        set { }
    }

    override var accessibilityValue: String? {
        get {
            if inputTextField.text?.isEmpty ?? true {
                return NSLocalizedString("Empty", comment: "Accessibility text for Unit Input cell")
            } else {
                return (inputTextField.text ?? "") + " " + (unitLabel.text ?? "")
            }
        }
        set { }
    }
}
