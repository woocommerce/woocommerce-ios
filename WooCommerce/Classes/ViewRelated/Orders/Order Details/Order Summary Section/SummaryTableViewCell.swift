import UIKit
import Yosemite
import Gridicons

struct SummaryTableViewCellPresentation {
    let status: OrderStatusEnum
    let statusName: String
}

/// The ViewModel for `SummaryTableViewCell`.
///
/// TODO This and that cell class should be renamed to be less ambiguous.
///
struct SummaryTableViewCellViewModel {
    private let billingAddress: Address?
    private let dateCreated: Date

    init(order: Order) {
        billingAddress = order.billingAddress
        dateCreated = order.dateCreated
    }

    var billedPersonName: String {
        if let billingAddress = billingAddress {
            return "\(billingAddress.firstName) \(billingAddress.lastName)"
        } else {
            return ""
        }
    }
}

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

    func configure(_ viewModel: SummaryTableViewCellViewModel) {
        titleLabel.text = viewModel.billedPersonName
    }

    /// Displays the specified OrderStatus, and applies the right Label Style
    ///
    func display(presentation: SummaryTableViewCellPresentation) {
        paymentStatusLabel.applyStyle(for: presentation.status)
        paymentStatusLabel.text = presentation.statusName
    }

    // MARK: - Overridden Methods

    override func awakeFromNib() {
        super.awakeFromNib()

        configureBackground()
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
        paymentStatusLabel.layer.borderColor = UIColor.clear.cgColor
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

    func configureBackground() {
        applyDefaultBackgroundStyle()
    }

    /// Setup: Labels
    ///
    func configureLabels() {
        titleLabel.applyHeadlineStyle()
        titleLabel.accessibilityIdentifier = "summary-table-view-cell-title-label"
        createdLabel.applyFootnoteStyle()
        createdLabel.accessibilityIdentifier = "summary-table-view-cell-created-label"
        paymentStatusLabel.applyPaddedLabelDefaultStyles()
        paymentStatusLabel.accessibilityIdentifier = "summary-table-view-cell-payment-status-label"
    }

    func configureIcon() {
        updateStatusButton.applyIconButtonStyle(icon: .pencilImage)

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
