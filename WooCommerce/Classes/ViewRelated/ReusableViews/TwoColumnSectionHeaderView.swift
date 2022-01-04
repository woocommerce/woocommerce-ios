import UIKit


/// Renders a Section Header/Footer with two labels [Left / Right].
///
final class TwoColumnSectionHeaderView: UITableViewHeaderFooterView {

    /// Left Label
    ///
    @IBOutlet private weak var leftColumn: UILabel!

    /// Right Label
    ///
    @IBOutlet private weak var rightColumn: UILabel!

    /// Constraint of the top of left/right labels to the view's top margin.
    @IBOutlet private weak var topMarginSpacingConstraint: NSLayoutConstraint!

    /// The spacing from the top of left/right labels to the view's top margin. The default value matches the value in its xib
    /// There is an additional 8px top margin by default in iOS.
    var topMarginSpacing: CGFloat = 14 {
        didSet {
            topMarginSpacingConstraint.constant = topMarginSpacing
        }
    }

    /// Whether the label text is converted to uppercase.
    var shouldShowUppercase: Bool = true

    /// Left Label's Text
    ///
    var leftText: String? {
        get {
            return leftColumn.text
        }
        set {
            leftColumn.text = shouldShowUppercase ? newValue?.uppercased(): newValue
            leftColumn.isHidden = newValue == nil || newValue?.isEmpty == true
        }
    }

    /// Right Label's Text
    ///
    var rightText: String? {
        get {
            return rightColumn.text
        }
        set {
            rightColumn.text = shouldShowUppercase ? newValue?.uppercased(): newValue
            rightColumn.isHidden = newValue == nil || newValue?.isEmpty == true
        }
    }

    // MARK: - Overridden Methods

    override func awakeFromNib() {
        super.awakeFromNib()

        tintColor = .clear

        configureLabels()
    }
}

/// Private methods
///
private extension TwoColumnSectionHeaderView {
    func configureLabels() {
        leftColumn.applyFootnoteStyle()
        leftColumn.numberOfLines = 0
        leftColumn.textColor = .listIcon
        rightColumn.numberOfLines = 0
        rightColumn.textColor = .listIcon
        rightColumn.applyFootnoteStyle()
    }
}
