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
            leftColumn.text = newValue
        }
    }

    /// Right Label's Text
    ///
    var rightText: String? {
        get {
            return rightColumn.text
        }
        set {
            rightColumn.text = newValue
        }
    }

    // MARK: - Overridden Methods

    override func awakeFromNib() {
        super.awakeFromNib()
        tintColor = .clear
        leftColumn.applyFootnoteStyle()
        rightColumn.applyFootnoteStyle()
        leftColumn.textColor = StyleManager.sectionTitleColor
        rightColumn.textColor = StyleManager.sectionTitleColor
    }
}


// MARK: - Public Methods
//
extension TwoColumnSectionHeaderView {
    func configure(leftText: String?, rightText: String?) {
        leftColumn.text = leftText
        rightColumn.text = rightText
    }
}
