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

    /// Left Title Label: sets the style to a type of "active" color,
    /// to indicate that the cell is tappable.
    ///
    func leftTextIsActive(_ active: Bool) {
        if active {
            leftTitleLabel.applyPrimaryHeadlineStyle()
            return
        }

        leftTitleLabel.applyBodyStyle()
    }

    /// Right Title Label: sets the style to a type of "active" color,
    /// to indicate that the cell is tappable.
    ///
    func rightTextIsActive(_ active: Bool) {
        if active {
            rightTitleLabel.applyPrimaryHeadlineStyle()
            return
        }

        rightTitleLabel.applyBodyStyle()
    }

    /// Footnote: attributed text option
    ///
    func updateFootnoteAttributedText(_ attributedString: NSAttributedString?) {
        footnoteLabel.attributedText = attributedString
    }

    /// Footnote: text option
    ///
    func updateFootnoteText(_ footnoteText: String?) {
        footnoteLabel.text = footnoteText
    }

    /// Collapses the footnote inside the stack view
    ///
    func hideFootnote() {
        footnoteLabel.isHidden = true
    }

    /// Cell equivalent to viewDidLoad
    ///
    override func awakeFromNib() {
        super.awakeFromNib()

        configureBackground()
        configureLabels()
    }

    /// Reset the cell when it's recycled
    ///
    override func prepareForReuse() {
        super.prepareForReuse()

        footnoteLabel.isHidden = false
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
