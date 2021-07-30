import UIKit

/// Represents a cell with a Headline Label
///
final class HeadlineTableViewCell: UITableViewCell {
    @IBOutlet private weak var headlineLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        configureCell()
    }

    private func configureCell() {
        applyDefaultBackgroundStyle()
        headlineLabel?.accessibilityIdentifier = "headline-label"
        headlineLabel?.applyHeadlineStyle()
        setNeedsLayout()
    }

    func configure(headline: String) {
        headlineLabel.text = headline
    }
}
