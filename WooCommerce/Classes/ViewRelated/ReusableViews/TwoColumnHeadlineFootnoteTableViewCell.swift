import UIKit


/// Represents a cell with a two-column title "row"
/// and a footnote "row" below the titles
///
final class TwoColumnHeadlineFootnoteTableViewCell: UITableViewCell {

    @IBOutlet private weak var leftTitleLabel: UILabel!
    @IBOutlet private weak var rightTitleLabel: UILabel!
    @IBOutlet private weak var footnoteLabel: UILabel!

    /// Left title label text
    ///
    var leftText: String? {
        get {
            return leftTitleLabel?.text
        }
        set {
            leftTitleLabel?.text = newValue
        }
    }

    /// Right title label text
    ///
    var rightText: String? {
        get {
            return rightTitleLabel?.text
        }
        set {
            rightTitleLabel?.text = newValue
        }
    }

    /// Footnote label text
    ///
    var footnoteText: String? {
        get {
            return footnoteLabel?.text
        }
        set {
            footnoteLabel?.text = newValue
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        configureBackground()
        configureLabels()
    }
}

// MARK: - Private Methods
//
private extension TwoColumnHeadlineFootnoteTableViewCell {
    /// Setup: Cell background
    ///
    func configureBackground() {
        applyDefaultBackgroundStyle()
    }

    /// Setup: Labels
    ///
    func configureLabels() {
        leftTitleLabel.applyHeadlineStyle()
        rightTitleLabel.applyHeadlineStyle()
        footnoteLabel.applyFootnoteStyle()
    }
}
