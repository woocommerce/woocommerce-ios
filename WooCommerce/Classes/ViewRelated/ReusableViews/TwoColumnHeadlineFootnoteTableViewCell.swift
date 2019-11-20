import UIKit


/// Represents a cell with a two-column title "row"
/// and a footnote "row" below the titles
///
final class TwoColumnHeadlineFootnoteTableViewCell: UITableViewCell {

    /// We want this reusable cell to be styled the same everywhere it's used, so the IBOutlets are made private.
    ///
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

    func updateFootnoteAttributedText(_ attributedString: NSAttributedString?) {
        footnoteLabel.attributedText = attributedString
    }

    func updateFootnoteText(_ footnoteText: String?) {
        footnoteLabel.text = footnoteText
    }

    func toggleFootnote() {
        footnoteLabel.isHidden = !footnoteLabel.isHidden
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

    /// Setup: Style the labels
    ///
    func configureLabels() {
        leftTitleLabel.applyHeadlineStyle()
        rightTitleLabel.applyHeadlineStyle()
        footnoteLabel.applyFootnoteStyle()
    }
}
