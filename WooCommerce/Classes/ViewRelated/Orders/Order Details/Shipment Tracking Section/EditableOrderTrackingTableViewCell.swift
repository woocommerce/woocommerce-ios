import UIKit

/// Displays shipment tracking information associated to an Order.
///
final class EditableOrderTrackingTableViewCell: UITableViewCell {
    @IBOutlet private var topLine: UILabel!
    @IBOutlet private var middleLine: UILabel!
    @IBOutlet private var bottomLine: UILabel!
    private var deleteButton = UIButton(type: .detailDisclosure)

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
        selectionStyle = .none
    }

    private func configureTopLine() {
        topLine.applyBodyStyle()
        topLine.numberOfLines = 0
    }

    private func configureMiddleLine() {
        middleLine.applyHeadlineStyle()
        middleLine.numberOfLines = 0
    }

    private func configureBottomLine() {
        bottomLine.applyBodyStyle()
        bottomLine.numberOfLines = 0
    }

    private func configureActionButton() {
        let deleteIcon = UIImage.deleteImage
            .imageFlippedForRightToLeftLayoutDirection()
            .imageWithTintColor(.primary)

        deleteButton.setImage(deleteIcon!, for: .normal)
        deleteButton.addTarget(self, action: #selector(iconTapped), for: .touchUpInside)

        self.accessoryView = deleteButton

        configureActionButtonForVoiceOver()
    }
}


/// MARK: - Actions
private extension EditableOrderTrackingTableViewCell {
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
        deleteButton.accessibilityLabel = NSLocalizedString("Delete",
                                                             comment:
            "Accessibility hint for delete button in an individual Shipment Tracking in the order fulfillment screen")
        deleteButton.accessibilityHint = NSLocalizedString("Deletes a shipment's tracking information.",
                                                            comment:
            "Accessibility hint for Delete Shipment button in Order fulfillment screen")
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

    func getActionButton() -> UIButton {
        return deleteButton
    }
}
