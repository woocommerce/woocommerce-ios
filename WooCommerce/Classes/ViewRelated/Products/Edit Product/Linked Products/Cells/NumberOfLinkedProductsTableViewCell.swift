import UIKit

final class NumberOfLinkedProductsTableViewCell: UITableViewCell {

    @IBOutlet private weak var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        applyDefaultBackgroundStyle()
        configureLabels()
    }

    func configure(content: String) {
        titleLabel.text = content
    }
}

private extension NumberOfLinkedProductsTableViewCell {

    func configureLabels() {
        titleLabel.applySubheadlineStyle()
    }
}
