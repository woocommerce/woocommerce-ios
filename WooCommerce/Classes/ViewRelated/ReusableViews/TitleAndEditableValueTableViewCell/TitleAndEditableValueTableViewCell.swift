import UIKit

final class TitleAndEditableValueTableViewCell: UITableViewCell {
    @IBOutlet private weak var stackView: UIStackView!
    @IBOutlet private weak var title: UILabel!
    @IBOutlet private weak var value: UITextField!

    private var viewModel: TitleAndEditableValueTableViewCellViewModel?

    enum Style {
        /// Small title. This is the default.
        case condensed
        /// Normal-sized title with subtle color.
        case relaxed

        fileprivate static let `default` = Self.condensed
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        configureBackground()
        configureAsNonSelectable()
        applyStyle(Style.default)
        configureStackView()
        observeValueTextFieldChanges()
    }

    /// Change the style add the `viewModel` represented by this view.
    func update(style: Style = .condensed, viewModel: TitleAndEditableValueTableViewCellViewModel?) {
        title.text = viewModel?.title
        value.placeholder = viewModel?.placeholder
        value.text = viewModel?.currentValue
        value.isEnabled = viewModel?.allowsEditing ?? false

        if viewModel?.hidesKeyboardOnReturn == true {
            value.addTarget(value, action: #selector(resignFirstResponder), for: UIControl.Event.editingDidEndOnExit)
        }

        self.viewModel = viewModel

        applyStyle(style)
    }
}


private extension TitleAndEditableValueTableViewCell {
    func configureBackground() {
        applyDefaultBackgroundStyle()
    }

    func configureAsNonSelectable() {
        selectionStyle = .none
    }

    func configureStackView() {
        stackView.spacing = Constants.stackViewSpacing
    }

    func applyStyle(_ style: Style) {
        switch style {
        case .condensed:
            title.applyFootnoteStyle()
        case .relaxed:
            title.applyBodyStyle()
            title.textColor = .textSubtle
        }

        value.applyBodyStyle()
    }

    func observeValueTextFieldChanges() {
        value.addTarget(self, action: #selector(updateViewModelValue), for: .editingChanged)
    }

    @objc func updateViewModelValue(sender textField: UITextField) {
        viewModel?.update(value: textField.text)
    }
}

// MARK: - Constants!
//
private extension TitleAndEditableValueTableViewCell {

    enum Constants {
        static let stackViewSpacing: CGFloat = 8
    }
}
