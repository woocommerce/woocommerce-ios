import UIKit

/// Displays shipment tracking information associated to an Order.
///
final class OrderTrackingTableViewCell: UITableViewCell {
    @IBOutlet private var topLine: UILabel!
    @IBOutlet private var middleLine: UILabel!
    @IBOutlet private var bottomLine: UILabel!
    @IBOutlet private var topBorder: UIView!
    private var ellipsisButton = UIButton(type: .detailDisclosure)

    var onEllipsisTouchUp: (() -> Void)?

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

    override func awakeFromNib() {
        super.awakeFromNib()

        configureBackground()
        configureTopLine()
        configureMiddleLine()
        configureBottomLine()
        configureActionButton()
    }

    private func configureBackground() {
        applyDefaultBackgroundStyle()
    }

    private func configureTopLine() {
        topLine.applySubheadlineStyle()
        topLine.numberOfLines = 0
    }

    private func configureMiddleLine() {
        middleLine.applyHeadlineStyle()
    }

    private func configureBottomLine() {
        bottomLine.applySubheadlineStyle()
        bottomLine.numberOfLines = 0
    }

    private func configureActionButton() {
        let moreIcon = UIImage.moreImage
            .imageFlippedForRightToLeftLayoutDirection()

        ellipsisButton.applyIconButtonStyle(icon: moreIcon)
        ellipsisButton.addTarget(self, action: #selector(iconTapped), for: .touchUpInside)

        self.accessoryView = ellipsisButton

        configureActionButtonForVoiceOver()
    }
}


/// MARK: - Actions
private extension OrderTrackingTableViewCell {
    @objc func iconTapped() {
        onEllipsisTouchUp?()
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
        ellipsisButton.accessibilityLabel = NSLocalizedString("More",
                                                            comment:
            "Accessibility hint for more button in an individual Shipment Tracking in the order details screen")
        ellipsisButton.accessibilityHint = NSLocalizedString("Shows more options.",
                                                           comment:
            "Accessibility hint for Delete Shipment button in Order details screen")
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
        return ellipsisButton
    }
}
