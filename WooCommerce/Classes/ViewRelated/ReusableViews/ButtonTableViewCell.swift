import UIKit

/// Displays a button inside a `UITableViewCell`.
///
final class ButtonTableViewCell: UITableViewCell {
    @IBOutlet public var button: UIButton!

    var onFullfillTouchUp: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        configureBackground()
        configureFulfillButton()
    }
}

extension ButtonTableViewCell {
    @IBAction func sendButtonTouchUpEvent() {
        onFullfillTouchUp?()
    }
}


private extension ButtonTableViewCell {
    func configureBackground() {
        applyDefaultBackgroundStyle()
    }

    func configureFulfillButton() {
        button.applyPrimaryButtonStyle()
    }
}
