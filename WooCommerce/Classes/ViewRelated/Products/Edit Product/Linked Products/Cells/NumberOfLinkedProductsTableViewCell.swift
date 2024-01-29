import UIKit

final class NumberOfLinkedProductsTableViewCell: UITableViewCell {

    @IBOutlet private weak var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        configureDefaultBackgroundConfiguration()
        configureLabels()
    }

    func configure(content: String) {
        titleLabel.text = content
    }

    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        updateDefaultBackgroundConfiguration(using: state)
    }
}

private extension NumberOfLinkedProductsTableViewCell {

    func configureLabels() {
        titleLabel.applySubheadlineStyle()
    }
}
