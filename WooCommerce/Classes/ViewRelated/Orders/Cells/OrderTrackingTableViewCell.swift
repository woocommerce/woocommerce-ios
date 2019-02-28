import UIKit

/// Displays shipment tracking information associated to an Order.
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
            configureTopLineForVoiceOver()
        }
    }

    var bottomText: String? {
        get {
            return bottomLine.text
        }
        set {
            bottomLine.text = newValue
            configureBottonLineForVoiceOver()
        }
    }

    var actionButtonNormalText: String? {
        get {
            return actionButton.title(for: .normal)
        }
        set {
            actionButton.setTitle(newValue, for: .normal)
            configureActionButtonForVoiceOver()
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

/// MARK: - Accessibility
///
private extension OrderTrackingTableViewCell {
    func configureTopLineForVoiceOver() {
        topLine.accessibilityLabel = String.localizedStringWithFormat(
            NSLocalizedString("Shipment Company %@",
                              comment: "Accessibility label for Shipment tracking company in Order details screen." +
                " Reads like: Shipment Company USPS"),
            topText ?? "")
    }

    func configureBottonLineForVoiceOver() {
        bottomLine.accessibilityLabel = String.localizedStringWithFormat(
            NSLocalizedString("Tracking number %@",
                                                                                           comment: "Accessibility label for Shipment tracking number in Order details screen. "
                                                                                            + "Reads like: Tracking Number 1AZ234567890"),
                                                                         bottomText ?? "")
    }

    func configureActionButtonForVoiceOver() {
        actionButton.accessibilityLabel = actionButtonNormalText
        actionButton.accessibilityTraits = .button
        actionButton.accessibilityHint = NSLocalizedString("Tracks a shipment.",
                                                           comment:
            "Accessibility hint for Track Package button in Order details screen")
    }
}


/// MARK: - Expose private outlets for tests
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
