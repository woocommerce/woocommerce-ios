import UIKit

/// Displays an item to be refunded
///
final class RefundItemTableViewCell: UITableViewCell {

    /// Item image view: Product image
    ///
    @IBOutlet private var itemImageView: UIImageView!

    /// Item title: Product name
    ///
    @IBOutlet private var itemTitle: UILabel!

    /// Item caption: Product quanity and price
    ///
    @IBOutlet private var itemCaption: UILabel!

    /// Quantity button: Quantity to be refunded
    ///
    @IBOutlet private var itemQuantityButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
    }
}

// MARK: Actions
private extension RefundItemTableViewCell {
    @IBAction func quantityButtonPressed(_ sender: Any) {
        print("Item quantity button pressed")
    }
}
