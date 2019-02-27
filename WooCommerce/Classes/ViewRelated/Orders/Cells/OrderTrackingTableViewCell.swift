import UIKit

/// Displays tracking information associated to an Order.
///
final class OrderTrackingTableViewCell: UITableViewCell {
    @IBOutlet private var topLine: UILabel!
    @IBOutlet private var bottomLine: UILabel!

    @IBOutlet private var actionButton: UIButton!

    var onActionTouchUp: (() -> Void)?

    var topText: String? {
        get {
            return topLine.text
        }
        set {
            topLine.text = newValue
        }
    }

    var bottomText: String? {
        get {
            return bottomLine.text
        }
        set {
            bottomLine.text = newValue
        }
    }

    var actionButtonNormalText: String? {
        get {
            return actionButton.title(for: .normal)
        }
        set {
            actionButton.setTitle(newValue, for: .normal)
            actionButton.accessibilityLabel = newValue
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        configureTopLine()
        configureBottomLine()
        configureActionButton()
    }

    private func configureTopLine() {
        topLine.applyHeadlineStyle()
    }

    private func configureBottomLine() {
        bottomLine.applySubheadlineStyle()
    }

    private func configureActionButton() {
        actionButton.applySecondaryButtonStyle()
        configureActionButtonForVoiceOver()
    }
}

extension OrderTrackingTableViewCell {
    @IBAction func actionButtonPressed(_ sender: Any) {
        onActionTouchUp?()
    }
}

/// Accessibility
///
private extension OrderTrackingTableViewCell {
    func configureActionButtonForVoiceOver() {
        actionButton.accessibilityTraits = .button
        actionButton.accessibilityHint = NSLocalizedString("Tracks a shipment.", comment: "Accessibility hint for Track Package button in Order details screen")
    }
}

/// Expose private outlets for tests
///
extension OrderTrackingTableViewCell {
    func getTopLabel() -> UILabel {
        return topLine
    }

    func getBottomLabel() -> UILabel {
        return bottomLine
    }

    func getActionButton() -> UIButton {
        return actionButton
    }
}
