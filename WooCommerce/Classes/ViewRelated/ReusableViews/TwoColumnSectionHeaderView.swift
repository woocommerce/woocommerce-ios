import UIKit


/// Renders a Section Header/Footer with two labels [Left / Right].
///
class TwoColumnSectionHeaderView: UITableViewHeaderFooterView {

    /// Left Label
    ///
    @IBOutlet private weak var leftColumn: UILabel!

    /// Right Label
    ///
    @IBOutlet private weak var rightColumn: UILabel!

    /// Left Label's Text
    ///
    var leftText: String? {
        get {
            return leftColumn.text
        }
        set {
            leftColumn.text = newValue?.uppercased()
        }
    }

    /// Right Label's Text
    ///
    var rightText: String? {
        get {
            return rightColumn.text
        }
        set {
            rightColumn.text = newValue?.uppercased()
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
