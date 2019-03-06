import UIKit

/// Displays shipment tracking information associated to an Order.
///
final class OrderTrackingTableViewCell: UITableViewCell {
    @IBOutlet private var topLine: UILabel!
    @IBOutlet private var middleLine: UILabel!
    @IBOutlet private var bottomLine: UILabel!
    @IBOutlet private var topBorder: UIView!
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

    var middleText: String? {
        get {
            return middleLine.text
        }
        set {
            middleLine.text = newValue
            configureMiddleLineForVoiceOver()
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
        configureButtonSeparator()
        configureTopLine()
        configureMiddleLine()
        configureBottomLine()
        configureActionButton()
    }

    private func configureButtonSeparator() {
        topBorder.backgroundColor = StyleManager.wooGreyBorder
    }

    private func configureTopLine() {
        topLine.applySubheadlineStyle()
    }

    private func configureMiddleLine() {
        middleLine.applyHeadlineStyle()
    }

    private func configureBottomLine() {
        bottomLine.applySubheadlineStyle()
    }

    private func configureActionButton() {
        actionButton.applyTertiaryButtonStyle()
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

    func configureMiddleLineForVoiceOver() {
        middleLine.accessibilityLabel = String.localizedStringWithFormat(
            NSLocalizedString("Tracking number %@",
                              comment: "Accessibility label for Shipment tracking number in Order details screen. Reads like: Tracking Number 1AZ234567890"),
            middleText ?? "")
    }

    func configureBottonLineForVoiceOver() {
        bottomLine.accessibilityLabel = String.localizedStringWithFormat(
            NSLocalizedString("Shipped %@",
                              comment: "Accessibility label for Shipment date in Order details screen. Shipped: February 27, 2018."),
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

    func getMiddleLabel() -> UILabel {
        return middleLine
    }

    func getBottomLabel() -> UILabel {
        return bottomLine
    }

    func getActionButton() -> UIButton {
        return actionButton
    }
}
