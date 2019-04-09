import UIKit

/// Displays shipment tracking information associated to an Order.
///
final class EditableOrderTrackingTableViewCell: UITableViewCell {
    @IBOutlet private var topLine: UILabel!
    @IBOutlet private var middleLine: UILabel!
    @IBOutlet private var bottomLine: UILabel!
    @IBOutlet private weak var icon: UIImageView!

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
        configureAsSelectable()
        configureTopLine()
        configureMiddleLine()
        configureBottomLine()
        configureActionButton()
    }

    private func configureAsSelectable() {
        selectionStyle = .default
    }

    private func configureTopLine() {
        topLine.applyBodyStyle()
    }

    private func configureMiddleLine() {
        middleLine.applyHeadlineStyle()
    }

    private func configureBottomLine() {
        bottomLine.applyBodyStyle()
    }

    private func configureActionButton() {
        let pencilIcon = UIImage.pencilImage
            .imageFlippedForRightToLeftLayoutDirection()
            .imageWithTintColor(StyleManager.wooCommerceBrandColor)

        icon.image = pencilIcon
    }
}

/// MARK: - Accessibility
///
private extension EditableOrderTrackingTableViewCell {
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
//        actionButton.accessibilityLabel = actionButtonNormalText
//        actionButton.accessibilityTraits = .button
//        actionButton.accessibilityHint = NSLocalizedString("Tracks a shipment.",
//                                                           comment:
//            "Accessibility hint for Track Package button in Order details screen")
    }
}

/// MARK: - Expose private outlets for tests
///
extension EditableOrderTrackingTableViewCell {
    func getTopLabel() -> UILabel {
        return topLine
    }

    func getMiddleLabel() -> UILabel {
        return middleLine
    }

    func getBottomLabel() -> UILabel {
        return bottomLine
    }

    func getActionButton() -> UIImageView {
        return icon
    }
}
