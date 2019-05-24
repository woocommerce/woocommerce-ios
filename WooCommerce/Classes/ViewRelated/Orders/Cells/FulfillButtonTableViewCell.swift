import UIKit


/// Displays the list of Products associated to an Order.
///
class FulfillButtonTableViewCell: UITableViewCell {
    @IBOutlet public var fulfillButton: UIButton!

    var onFullfillTouchUp: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        fulfillButton.applyPrimaryButtonStyle()
    }
}

extension FulfillButtonTableViewCell {
    @IBAction func fulfillWasPressed() {
        onFullfillTouchUp?()
    }
}
