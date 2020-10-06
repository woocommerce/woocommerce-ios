import UIKit

final class TitleAndEditableValueTableViewCell: UITableViewCell {
    @IBOutlet private weak var stackView: UIStackView!
    // TODO Make this private and use `update()` instead.
    @IBOutlet weak var title: UILabel!
    // TODO Make this private and use `update()` instead.
    @IBOutlet weak var value: UITextField!

    enum Style {
        /// Small title. This is the default.
        case condensed
        /// Normal-sized title with subtle color.
        case relaxed

        static let `default` = Self.condensed
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        configureBackground()
        configureAsNonSelectable()
        applyStyle(Style.default)
        configureStackView()
    }

    /// Updates the values for the labels.
    func update(style: Style = .condensed, title: String?, placeholder: String?) {
        self.title.text = title
        self.value.placeholder = placeholder

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
}

// MARK: - Constants!
//
private extension TitleAndEditableValueTableViewCell {

    enum Constants {
        static let stackViewSpacing: CGFloat = 7
    }
}
