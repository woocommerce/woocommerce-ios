import UIKit

/// Displays shipment tracking information associated to an Order.
///
final class EditableOrderTrackingTableViewCell: UITableViewCell {
    @IBOutlet private var topLine: UILabel!
    @IBOutlet private var middleLine: UILabel!
    @IBOutlet private var bottomLine: UILabel!
    @IBOutlet private weak var icon: UIImageView!

    var onDeleteTouchUp: (() -> Void)?

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
        let pencilIcon = UIImage.deleteImage
            .imageFlippedForRightToLeftLayoutDirection()
            .imageWithTintColor(StyleManager.wooCommerceBrandColor)

        icon.image = pencilIcon

        configureActionButtonForVoiceOver()

        configureIconTapGesture()
    }
}


/// MARK: - Actions
private extension EditableOrderTrackingTableViewCell {
    func configureIconTapGesture() {
        icon.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(iconTapped))
        icon.addGestureRecognizer(tapGesture)
    }

    @objc func iconTapped() {
        onDeleteTouchUp?()
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
        icon.accessibilityLabel = NSLocalizedString("Edit",
                                                            comment:
            "Accessibility hint for Pencil button in an individual Shipment Tracking in the order fulfillment screen")
        icon.accessibilityTraits = .button
        icon.accessibilityHint = NSLocalizedString("Edits a shipment.",
                                                           comment:
            "Accessibility hint for Edit Shipment button in Order fulfillment screen")
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
