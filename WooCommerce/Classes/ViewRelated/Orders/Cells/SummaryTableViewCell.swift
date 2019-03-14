import UIKit
import Yosemite
import Gridicons


// MARK: - SummaryTableViewCell
//
final class SummaryTableViewCell: UITableViewCell {

    /// Label: Title
    ///
    @IBOutlet private weak var titleLabel: UILabel!

    /// Label: Creation / Update Date
    ///
    @IBOutlet private weak var createdLabel: UILabel!

    /// Label: Payment Status
    ///
    @IBOutlet private weak var paymentStatusLabel: PaddedLabel!

    /// Button: Manually Update Order Status
    ///
    @IBOutlet private var updateStatusButton: UIButton!

    /// Title
    ///
    var title: String? {
        get {
            return titleLabel.text
        }
        set {
            titleLabel.text = newValue
        }
    }

    /// Date
    ///
    var dateCreated: String? {
        get {
            return createdLabel.text
        }
        set {
            createdLabel.text = newValue
        }
    }

    /// Closure to be executed whenever the edit button is tapped.
    ///
    var onEditTouchUp: (() -> Void)?

    /// Displays the specified OrderStatus, and applies the right Label Style
    ///
    func display(viewModel: OrderDetailsViewModel) {
        if let orderStatus = viewModel.orderStatus {
            paymentStatusLabel.applyStyle(for: orderStatus.status)
            paymentStatusLabel.text = orderStatus.name
        } else {
            // There are unsupported extensions with even more statuses available.
            // So let's use the order.statusKey to display those as slugs.
            let statusKey = viewModel.order.statusKey
            let statusEnum = OrderStatusEnum(rawValue: statusKey)
            paymentStatusLabel.applyStyle(for: statusEnum)
            paymentStatusLabel.text = viewModel.order.statusKey
        }
    }


    // MARK: - Overridden Methods

    override func awakeFromNib() {
        super.awakeFromNib()
        configureLabels()
        configureIcon()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        preserveLabelColors {
            super.setSelected(selected, animated: animated)
        }
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        preserveLabelColors {
            super.setHighlighted(highlighted, animated: animated)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
    }
}


// MARK: - Private
//
private extension SummaryTableViewCell {

    /// Preserves the current Payment BG Color
    ///
    func preserveLabelColors(action: () -> Void) {
        let paymentColor = paymentStatusLabel.backgroundColor
        let borderColor = paymentStatusLabel.layer.borderColor

        action()

        paymentStatusLabel.backgroundColor = paymentColor
        paymentStatusLabel.layer.borderColor = borderColor
    }

    /// Setup: Labels
    ///
    func configureLabels() {
        titleLabel.applyHeadlineStyle()
        createdLabel.applyFootnoteStyle()
        paymentStatusLabel.applyPaddedLabelDefaultStyles()
    }

    func configureIcon() {
        updateStatusButton.setImage(.pencilImage, for: .normal)

        updateStatusButton.addTarget(self, action: #selector(editWasTapped), for: .touchUpInside)

        configureIconForVoiceOver()
    }

    @objc func editWasTapped() {
        onEditTouchUp?()
    }
}


/// MARK: - VoiceOver
///
private extension SummaryTableViewCell {
    func configureIconForVoiceOver() {
        updateStatusButton.accessibilityLabel = NSLocalizedString("Update Order Status",
                                                                  comment: "Accessibility label for the button to update the order status in Order Details")
        updateStatusButton.accessibilityTraits = .button
        updateStatusButton.accessibilityHint = NSLocalizedString("Opens a list of available statuses.",
                                                                 comment: "Accessibility hint for the button to update the order status")
    }
}


/// MARK: - Testability
extension SummaryTableViewCell {
    func getTitle() -> UILabel {
        return titleLabel
    }

    func getCreatedLabel() -> UILabel {
        return createdLabel
    }

    func getStatusLabel() -> UILabel {
        return paymentStatusLabel
    }

    func getEditButton() -> UIButton {
        return updateStatusButton
    }
}
