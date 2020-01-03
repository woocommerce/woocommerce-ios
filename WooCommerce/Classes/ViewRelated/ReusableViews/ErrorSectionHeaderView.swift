import UIKit

/// Displays error for the table view section.
///
final class ErrorSectionHeaderView: UITableViewHeaderFooterView {

    @IBOutlet private weak var titleLabel: UILabel!

    // MARK: - Overridden Methods

    override func awakeFromNib() {
        super.awakeFromNib()

        tintColor = .clear

        configureTitleLabel()
    }

    func configure(title: String?) {
        titleLabel.text = title
    }
}

/// Configurations
///
private extension ErrorSectionHeaderView {
    func configureTitleLabel() {
        titleLabel.applySubheadlineStyle()
        titleLabel.numberOfLines = 0
        titleLabel.textColor = .error
    }
}
