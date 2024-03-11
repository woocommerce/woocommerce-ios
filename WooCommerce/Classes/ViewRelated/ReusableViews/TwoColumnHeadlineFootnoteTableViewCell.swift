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

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

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

    /// Left Title Label: sets the style to the accent color,
    /// to indicate that the cell is tappable.
    ///
    func setLeftTitleToLinkStyle(_ active: Bool) {
        if active {
            leftTitleLabel.applyLinkHeadlineStyle()
            return
        }

        leftTitleLabel.applyBodyStyle()
    }

    /// Right Title Label: sets the style to the accent color,
    /// to indicate that the cell is tappable.
    ///
    func setRightTitleToLinkStyle(_ active: Bool) {
        if active {
            rightTitleLabel.applyLinkHeadlineStyle()
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
        configureActivityIndicator()
    }

    /// Reset the cell when it's recycled
    ///
    override func prepareForReuse() {
        super.prepareForReuse()

        footnoteLabel.isHidden = false
        configureLabels()
    }

    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        updateDefaultBackgroundConfiguration(using: state)
    }

    func startLoading() {
        activityIndicator.startAnimating()
        isUserInteractionEnabled = false
        alpha = 0.5
    }

    func stopLoading() {
        activityIndicator.stopAnimating()
        isUserInteractionEnabled = true
        alpha = 1
    }
}

// MARK: - Private Methods
//
private extension TwoColumnHeadlineFootnoteTableViewCell {

    /// Setup: Cell background
    ///
    func configureBackground() {
        configureDefaultBackgroundConfiguration()
    }

    /// Setup: Style the labels
    ///
    func configureLabels() {
        leftTitleLabel.applyHeadlineStyle()
        rightTitleLabel.applyHeadlineStyle()
        footnoteLabel.applyFootnoteStyle()
    }

    func configureActivityIndicator() {
        addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
        ])
    }
}
