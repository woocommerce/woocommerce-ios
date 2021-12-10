import UIKit

final class RefundFeesDetailsTableViewCell: UITableViewCell {
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

    /// Displays `Total` title
    ///
    @IBOutlet private var totalTitleLabel: UILabel!

    /// DIsplays the total value
    ///
    @IBOutlet private var totalPriceLabel: UILabel!
}
