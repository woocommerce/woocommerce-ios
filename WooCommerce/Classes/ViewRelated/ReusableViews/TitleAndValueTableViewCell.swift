import UIKit

final class TitleAndValueTableViewCell: UITableViewCell {

    @IBOutlet private weak var stackView: UIStackView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var valueLabel: UILabel!

    enum Style {
        /// Title and value use body styles. The value uses a subtle color. This is the default.
        case regular
        /// Both the title and value use body styles and colors.
        case bodyConsistent
        /// Same as regular except the value uses a tertiary text color.
        case nonSelectable
        /// Title and value will use headline (bold) styles.
        case headline

        fileprivate static let `default` = Self.regular
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        applyDefaultBackgroundStyle()
        enableMultipleLines()
        apply(style: .default)
        configureStackView()
    }
}

// MARK: Updates
//
extension TitleAndValueTableViewCell {
    func updateUI(title: String, value: String?) {
        titleLabel.text = title
        valueLabel.text = value
        apply(style: .default)
    }

    /// Change the styling of the UI elements. 
    func apply(style: Style) {
        switch style {
        case .regular:
            titleLabel.applyBodyStyle()
            titleLabel.textColor = .text

            valueLabel.applyBodyStyle()
            valueLabel.textColor = .textSubtle
        case .bodyConsistent:
            titleLabel.applyBodyStyle()
            valueLabel.applyBodyStyle()
        case .nonSelectable:
            titleLabel.applyBodyStyle()
            titleLabel.textColor = .text

            valueLabel.applyBodyStyle()
            valueLabel.textColor = .textTertiary
        case .headline:
            titleLabel.applyHeadlineStyle()
            valueLabel.applyHeadlineStyle()
        }
    }

    /// Needed specially when dealing with big accessibility traits
    ///
    func enableMultipleLines() {
        titleLabel.numberOfLines = 0
        valueLabel.numberOfLines = 0
    }
}

private extension TitleAndValueTableViewCell {
    func configureStackView() {
        stackView.spacing = Constants.spacingBetweenTitleAndValue
        stackView.alignment = .center
    }
}

private extension TitleAndValueTableViewCell {
    enum Constants {
        static let spacingBetweenTitleAndValue = CGFloat(12)
    }
}
