import UIKit


/// Represents a cell with a Title Label and Body Label
///
final class HeadlineLabelTableViewCell: UITableViewCell {
    @IBOutlet private weak var headlineLabel: UILabel?
    @IBOutlet private weak var bodyLabel: UILabel?
    /// The spacing between the `headlineLabel` and the `bodyLabel`.
    @IBOutlet private var headlineToBodyConstraint: NSLayoutConstraint!

    enum Style {
        /// Bold title with no margin against the body. Hard colors. This is the default.
        case compact
        /// Normal body title with a margin against the body. The title uses body style while
        /// the body uses secondary style.
        case regular

        fileprivate static let `default` = Self.compact
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        configureBackground()
        configureHeadline()
        configureBody()
        apply(style: .default)
    }

    /// Update the UI style and label values.
    func update(style: Style = .default, headline: String?, body: String?) {
        headlineLabel?.text = headline
        bodyLabel?.text = body
        apply(style: style)
    }
}


private extension HeadlineLabelTableViewCell {
    func configureBackground() {
        applyDefaultBackgroundStyle()
    }

    func configureHeadline() {
        headlineLabel?.accessibilityIdentifier = "headline-label"
    }

    func configureBody() {
        bodyLabel?.accessibilityIdentifier = "body-label"
    }

    func apply(style: Style) {
        switch style {
        case .compact:
            headlineLabel?.applyHeadlineStyle()
            bodyLabel?.applyBodyStyle()
            headlineToBodyConstraint.constant = 0
        case .regular:
            headlineLabel?.applyBodyStyle()
            bodyLabel?.applySecondaryBodyStyle()
            headlineToBodyConstraint.constant = Dimensions.margin
        }

        setNeedsLayout()
    }
}

// MARK: - Constants

private extension HeadlineLabelTableViewCell {
    enum Dimensions {
        static let margin: CGFloat = 8.0
    }
}
