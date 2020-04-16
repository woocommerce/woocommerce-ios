import UIKit

/// Displays a Product Category Row
///
final class ProductCategoryTableViewCell: UITableViewCell {

    /// Label to display the category name
    ///
    @IBOutlet private var nameLabel: UILabel!

    /// Leading constraint of the category name label
    ///
    @IBOutlet private var leadingNameLabelConstraint: NSLayoutConstraint!

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
        leadingNameLabelConstraint.constant = Constants.baseNameLabelMargin
    }

    private func styleLabels() {
        nameLabel.applyBodyStyle()
    }

    private func styleCheckmark() {
        tintColor = .primary
    }

    /// Configure the cell with the given ViewModel
    ///
    func configure(with viewModel: ProductCategoryCellViewModel) {
        nameLabel.text = viewModel.name
        accessoryType = viewModel.isSelected ? .checkmark : .none
        leadingNameLabelConstraint.constant = Constants.baseNameLabelMargin + (Constants.nameLabelIndentationFactor * CGFloat(viewModel.indentationLevel))
    }
}

// MARK: - Constants!
//
private extension ProductCategoryTableViewCell {
    enum Constants {
        static let baseNameLabelMargin: CGFloat = 16.0
        static let nameLabelIndentationFactor: CGFloat = 16.0
    }
}
