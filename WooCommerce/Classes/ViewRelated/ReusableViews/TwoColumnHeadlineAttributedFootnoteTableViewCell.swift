import UIKit


/// Represents a cell with a two-column title "row"
/// and an attributed string footnote "row" below the titles
///
final class TwoColumnHeadlineAttributedFootnoteTableViewCell: UITableViewCell {

    /// We want this reusable cell to have a consistent appearance
    /// everywhere it's used, so we closed access to the labels.
    ///
    @IBOutlet private weak var leftTitleLabel: UILabel!
    @IBOutlet private weak var rightTitleLabel: UILabel!
    @IBOutlet private weak var footnoteLabel: UILabel!

    // Expose the properties of a label that should be available for configuration.

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

    /// Footnote label text
    ///
    var footnoteAttributedText: NSAttributedString? {
        get {
            return footnoteLabel?.attributedText
        }
        set {
            footnoteLabel?.attributedText = newValue
        }
    }

    /// Cell setup
    ///
    override func awakeFromNib() {
        super.awakeFromNib()
        configureBackground()
        configureLabels()
    }
}

// MARK: - Private Methods
//
private extension TwoColumnHeadlineAttributedFootnoteTableViewCell {

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
