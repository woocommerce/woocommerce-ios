import UIKit

/// TableViewCell that displays all information regarding shipping refunds
///
final class RefundShippingDetailsTableViewCell: UITableViewCell {

    /// Displays a truck image next to the carrier name
    ///
    @IBOutlet weak var shippingImageView: UIImageView!

    /// Displays the carrier name and shipping rate
    ///
    @IBOutlet weak var carrierLabel: UILabel!

    /// Display the shipping cost
    ///
    @IBOutlet weak var shippingPrice: UILabel!

    /// Displays `Subtotal` title
    ///
    @IBOutlet weak var subtotalTitleLabel: UILabel!

    /// Displays the subtotal value
    ///
    @IBOutlet weak var subtotalPriceLabel: UILabel!

    /// Displays `Tax` title
    ///
    @IBOutlet weak var taxTitleLabel: UILabel!

    /// Displays the tax value
    ///
    @IBOutlet weak var taxPriceLabel: UILabel!

    /// Displays `Shipping Refund` title
    ///
    @IBOutlet weak var shippingRefundTitleLabel: UILabel!

    /// Displays the total shipping cost to refund
    ///
    @IBOutlet weak var shippingRefundPriceLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
