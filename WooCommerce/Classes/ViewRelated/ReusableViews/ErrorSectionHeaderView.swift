import UIKit

/// Displays error for the table view section.
///
final class ErrorSectionHeaderView: UITableViewHeaderFooterView {

    @IBOutlet weak var titleLabelTopSpacing: NSLayoutConstraint!
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

    func addTopSpacing() {
        titleLabelTopSpacing.constant = 22
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
