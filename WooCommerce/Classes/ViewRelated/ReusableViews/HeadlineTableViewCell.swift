import UIKit

/// Represents a cell with a Headline Label
///
final class HeadlineTableViewCell: UITableViewCell {
    @IBOutlet private weak var headlineLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        configureCell()
    }

    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        updateDefaultBackgroundConfiguration(using: state)
    }

    private func configureCell() {
        configureDefaultBackgroundConfiguration()
        headlineLabel?.accessibilityIdentifier = "headline-label"
        headlineLabel?.applyHeadlineStyle()
        setNeedsLayout()
    }

    func configure(headline: String) {
        headlineLabel.text = headline
    }
}
