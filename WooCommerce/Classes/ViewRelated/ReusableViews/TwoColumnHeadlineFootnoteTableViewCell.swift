import UIKit


/// Represents a cell with a two-column title "row"
/// and a footnote "row" below the titles
///
/// Note that you can set plain text or attributed text
/// in the footnote.
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

    /// Footnote label attributed string
    ///
    var footnoteAttributedText: NSAttributedString? {
        get {
            return footnoteLabel.attributedText
        }
        set {
            footnoteLabel?.attributedText = newValue
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        configureBackground()
        configureLabels()
        configureFootnoteLabel()
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
    }

    /// Setup: Footnote Label
    ///
    func configureFootnoteLabel() {
        guard footnoteLabel?.attributedText?.string.count == 0 else {
//            footnoteLabel.applySecondaryFootnoteStyle()
            return
        }
        footnoteLabel.applyFootnoteStyle()
    }
}
