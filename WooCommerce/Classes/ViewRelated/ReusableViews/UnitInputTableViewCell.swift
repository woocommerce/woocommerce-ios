import UIKit

struct UnitInputViewModel {
    let title: String
    let unit: String
    let value: String?
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
    }

    func configure(viewModel: UnitInputViewModel) {
        titleLabel.text = viewModel.title
        unitLabel.text = viewModel.unit
        unitLabel.isHidden = viewModel.unit.isEmpty
        inputTextField.text = viewModel.value
        inputTextField.keyboardType = viewModel.keyboardType
        inputFormatter = viewModel.inputFormatter
        onInputChange = viewModel.onInputChange
    }
}

private extension UnitInputTableViewCell {
    func configureSelectionStyle() {
        selectionStyle = .none
    }

    func configureTitleLabel() {
        titleLabel.applyBodyStyle()
    }

    func configureInputAndUnitStackView() {
        inputAndUnitStackView.spacing = 6
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
    }

    func configureUnitLabel() {
        unitLabel.applyBodyStyle()
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
