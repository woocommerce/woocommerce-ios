import UIKit


/// Displays the list of Products associated to an Order.
///
class ProductListTableViewCell: UITableViewCell {
    @IBOutlet public var verticalStackView: UIStackView!
    @IBOutlet public var fulfillButton: UIButton!
    @IBOutlet public var actionContainerView: UIView!

    var onFullfillTouchUp: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        fulfillButton.applyPrimaryButtonStyle()
    }
}

extension ProductListTableViewCell {
    @IBAction func fulfillWasPressed() {
        onFullfillTouchUp?()
    }
}
