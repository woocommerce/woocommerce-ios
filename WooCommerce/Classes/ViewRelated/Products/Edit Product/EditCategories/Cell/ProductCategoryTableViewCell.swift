import UIKit

/// Displays a Product Category Row
///
final class ProductCategoryTableViewCell: UITableViewCell {

    /// Label to display the category name
    ///
    @IBOutlet private var nameLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        styleLabels()
        styleCheckmark()
    }

    override func prepareForReuse() {
        nameLabel.text = nil
        accessoryType = .none
    }

    private func styleLabels() {
        nameLabel.applyBodyStyle()
    }

    private func styleCheckmark() {
        tintColor = .primary
    }

    /// Configure the cell with the given content
    /// - Parameters:
    ///   - name: Product Category name
    ///   - selected: `true` renders  a chekmark, `false` renders nothing.
    func configure(name: String, selected: Bool) {
        nameLabel.text = name
        accessoryType = selected ? .checkmark : .none
    }
}
