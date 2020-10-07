import UIKit

/// Displays a button inside a `UITableViewCell`.
///
final class ButtonTableViewCell: UITableViewCell {
    @IBOutlet public var fulfillButton: UIButton!

    var onFullfillTouchUp: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        configureBackground()
        configureFulfillButton()
    }
}

extension ButtonTableViewCell {
    @IBAction func fulfillWasPressed() {
        onFullfillTouchUp?()
    }
}


private extension ButtonTableViewCell {
    func configureBackground() {
        applyDefaultBackgroundStyle()
    }

    func configureFulfillButton() {
        fulfillButton.applyPrimaryButtonStyle()
    }
}
