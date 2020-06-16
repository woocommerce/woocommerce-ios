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
        styleSelection()
        styleLabels()
        styleCheckmark()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
        accessoryType = .none
        leadingNameLabelConstraint.constant = Constants.baseNameLabelMargin
    }

    /// Configure the cell with the given ViewModel
    ///
    func configure(with viewModel: ProductCategoryCellViewModel) {
        nameLabel.text = viewModel.name
        accessoryType = viewModel.isSelected ? .checkmark : .none
        leadingNameLabelConstraint.constant = Constants.baseNameLabelMargin + (Constants.nameLabelIndentationFactor * CGFloat(viewModel.indentationLevel))
    }
}

private extension ProductCategoryTableViewCell {
    private func styleSelection() {
        self.selectionStyle = .none
    }

    private func styleLabels() {
        nameLabel.applyBodyStyle()
    }

    private func styleCheckmark() {
        tintColor = .primary
    }
}

// MARK: - Constants!
//
private extension ProductCategoryTableViewCell {
    enum Constants {
        static let baseNameLabelMargin: CGFloat = 16.0
        static let nameLabelIndentationFactor: CGFloat = 20.0
    }
}
