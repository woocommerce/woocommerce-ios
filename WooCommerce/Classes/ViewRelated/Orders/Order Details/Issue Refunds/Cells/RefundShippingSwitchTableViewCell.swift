import UIKit

/// Displays a switch to enable shipping refunds
///
final class RefundShippingSwitchTableViewCell: UITableViewCell {

    /// Title describing the refund shipping switch
    ///
    @IBOutlet private var shippingTitle: UILabel!

    /// Control Enables / Disables the shipping refund
    ///
    @IBOutlet private var shippingSwitch: UISwitch!

    override class func awakeFromNib() {
        super.awakeFromNib()
    }
}
