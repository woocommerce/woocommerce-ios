import UIKit

/// Displays a Product Category Row
///
final class ProductCategoryTableViewCell: UITableViewCell {

    /// Label to display the category name
    ///
    @IBOutlet private var nameLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        applyDefaultBackgroundStyle()
        styleLabels()
        styleCheckmark()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
        accessoryType = .none
    }

    private func styleLabels() {
        nameLabel.applyBodyStyle()
    }

    private func styleCheckmark() {
        tintColor = .primary
    }

    /// Configure the cell with the given ViewModel
    ///
    func configure(with viewModel: ProductCategoryViewModel) {
        nameLabel.text = viewModel.name
        accessoryType = viewModel.isSelected ? .checkmark : .none
    }
}
