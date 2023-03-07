import UIKit

class ValueOneTableViewCell: UITableViewCell {

    /// The style options for the `ValueOneTableViewCell`
    ///
    enum Style {
        /// Uses BodyStyle for the Text  and Subheadline for the DetailText.  This is the default.
        case primary
        /// The same as `primary` except that for the DetailText uses a Tertiary text color.
        case secondary
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        configureTextLabel()
        configureDetailTextLabel()
        apply(style: .primary)
    }

    /// Change the styling of the UI elements.
    ///
    func apply(style: Style) {
        configureTextLabel()
        configureDetailTextLabel()
        configureBackground()

        if style == .secondary {
            detailTextLabel?.textColor = .textTertiary
        }
    }

    func configure(with viewModel: ViewModel) {
        textLabel?.text = viewModel.text
        detailTextLabel?.text = viewModel.detailText
        apply(style: viewModel.style)
    }
}

// MARK: - CellViewModel subtype
//
extension ValueOneTableViewCell {
    struct ViewModel {
        let text: String
        let detailText: String
        let style: Style

        init(text: String, detailText: String, style: Style = .primary) {
            self.text = text
            self.detailText = detailText
            self.style = style
        }
    }
}

private extension ValueOneTableViewCell {
    enum Constants {
        static let cellValueTextColor = UIColor.systemColor(.secondaryLabel)
    }

    func configureBackground() {
        applyDefaultBackgroundStyle()
    }

    func configureTextLabel() {
        textLabel?.applyBodyStyle()
    }

    func configureDetailTextLabel() {
        detailTextLabel?.applySubheadlineStyle()
        detailTextLabel?.textColor = Constants.cellValueTextColor
        detailTextLabel?.lineBreakMode = .byWordWrapping
        detailTextLabel?.numberOfLines = 0
    }
}
