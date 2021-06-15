import UIKit

/// Represents a cell with a Headline Label
///
final class HeadlineTableViewCell: UITableViewCell {
    @IBOutlet weak var headlineLabel: UILabel?

    override func awakeFromNib() {
        super.awakeFromNib()
        configureCell()
    }

    func configureCell() {
        applyDefaultBackgroundStyle()
        headlineLabel?.accessibilityIdentifier = "headline-label"
        headlineLabel?.applyHeadlineStyle()
        setNeedsLayout()
    }
}
