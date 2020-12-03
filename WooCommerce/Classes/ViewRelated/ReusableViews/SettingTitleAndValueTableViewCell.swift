import UIKit

final class SettingTitleAndValueTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!

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
    }
}

// MARK: Updates
//
extension SettingTitleAndValueTableViewCell {
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
