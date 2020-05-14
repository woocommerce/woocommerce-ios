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
    private let orderNumber: String

    let presentation: SummaryTableViewCellPresentation

    private let calendar: Calendar
    private let layoutDirection: UIUserInterfaceLayoutDirection

    init(order: Order,
         status: OrderStatus?,
         calendar: Calendar = .current,
         layoutDirection: UIUserInterfaceLayoutDirection = UIApplication.shared.userInterfaceLayoutDirection) {

        billingAddress = order.billingAddress
        dateCreated = order.dateCreated
        orderNumber = order.number

        presentation = SummaryTableViewCellPresentation(
            status: status?.status ?? OrderStatusEnum(rawValue: order.statusKey),
            statusName: status?.name ?? order.statusKey
        )

        self.calendar = calendar
        self.layoutDirection = layoutDirection
    }

    /// The full name from the billing address
    ///
    var billedPersonName: String {
        if let billingAddress = billingAddress {
            return "\(billingAddress.firstName) \(billingAddress.lastName)"
        } else {
            return ""
        }
    }

    /// The date and the order number concatenated together. Example, “Jan 22, 2018 • #1587”.
    ///
    /// If the date is today, the time will be returned instead.
    ///
    var dateCreatedAndOrderNumber: String {
        let formatter: DateFormatter = {
            if dateCreated.isSameDay(as: Date(), using: calendar) {
                return DateFormatter.timeFormatter
            } else {
                return DateFormatter.mediumLengthLocalizedDateFormatter
            }
        }()

        return [formatter.string(from: dateCreated), "#\(orderNumber)"]
            .reversed(when: layoutDirection == .rightToLeft)
            .joined(separator: " • ")
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

    /// Closure to be executed whenever the edit button is tapped.
    ///
    var onEditTouchUp: (() -> Void)?

    func configure(_ viewModel: SummaryTableViewCellViewModel) {
        titleLabel.text = viewModel.billedPersonName
        createdLabel.text = viewModel.dateCreatedAndOrderNumber

        display(presentation: viewModel.presentation)
    }

    /// Displays the specified OrderStatus, and applies the right Label Style
    ///
    private func display(presentation: SummaryTableViewCellPresentation) {
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
