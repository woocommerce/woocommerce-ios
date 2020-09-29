import UIKit

/// `TableViewCell` that displays the products amount to be refunded
///
final class RefundProductsTotalTableViewCell: UITableViewCell {

    /// Displays `Subtotal` title
    ///
    @IBOutlet private var subtotalTitleLabel: UILabel!

    /// Displays the subtotal value
    ///
    @IBOutlet private var subtotalPriceLabel: UILabel!

    /// Displays `Tax` title
    ///
    @IBOutlet private var taxTitleLabel: UILabel!

    /// Displays the tax value
    ///
    @IBOutlet private var taxPriceLabel: UILabel!

    /// Displays `Products Refund` title
    ///
    @IBOutlet private var productsRefundTitleLabel: UILabel!

    /// Displays the total products costs to be refunded
    ///
    @IBOutlet private var productsRefundPriceLabel: UILabel!

    override class func awakeFromNib() {
        super.awakeFromNib()
    }
}
