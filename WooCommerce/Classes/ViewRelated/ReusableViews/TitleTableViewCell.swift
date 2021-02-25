import UIKit

/// Represents a cell with a Title Label
///
final class TitleTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel?

    override func awakeFromNib() {
        super.awakeFromNib()
        configureCell()
    }

    func configureCell() {
        applyDefaultBackgroundStyle()
        titleLabel?.accessibilityIdentifier = "title-label"
        titleLabel?.applyTitleStyle()
        setNeedsLayout()
    }
}
