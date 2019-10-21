import UIKit

/// Displays the list of Products associated to an Order.
///
final class FulfillButtonTableViewCell: UITableViewCell {
    @IBOutlet public var fulfillButton: UIButton!

    var onFullfillTouchUp: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        configureBackground()
        configureFulfillButton()
    }
}

extension FulfillButtonTableViewCell {
    @IBAction func fulfillWasPressed() {
        onFullfillTouchUp?()
    }
}


extension FulfillButtonTableViewCell {
    fileprivate func configureBackground() {
        applyDefaultBackgroundStyle()
    }

    fileprivate func configureFulfillButton() {
        fulfillButton.applyPrimaryButtonStyle()
    }
}
