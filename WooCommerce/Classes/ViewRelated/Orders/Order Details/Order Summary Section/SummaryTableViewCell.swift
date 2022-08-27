import UIKit
import Yosemite
import Gridicons

/// The ViewModel for `SummaryTableViewCell`.
///
/// TODO This and that cell class should be renamed to be less ambiguous.
///
struct SummaryTableViewCellViewModel {
    fileprivate struct OrderStatusPresentation {
        let style: OrderStatusEnum
        let title: String
    }

    private let billingAddress: Address?
    private let dateCreated: Date

    fileprivate let presentation: OrderStatusPresentation

    private let calendar: Calendar

    init(order: Order,
         status: OrderStatus?,
         calendar: Calendar = .current) {

        billingAddress = order.billingAddress
        dateCreated = order.dateCreated

        presentation = OrderStatusPresentation(
            style: status?.status ?? order.status,
            title: status?.name ?? order.status.rawValue
        )

        self.calendar = calendar
    }

    /// The full name from the billing address
    ///
    var billedPersonName: String {
        if let fullName = billingAddress?.fullName, fullName.isNotEmpty {
            return fullName
        } else {
            return Localization.guestName
        }
    }

    /// The date, time, and the order number concatenated together. Example, “Jan 22, 2018, 11:23 AM”.
    ///
    var subtitle: String {
        let formatter = DateFormatter.dateAndTimeFormatter
        return formatter.string(from: dateCreated)
    }
}

// MARK: - SummaryTableViewCell
//
final class SummaryTableViewCell: UITableViewCell {

    /// Label: Title
    ///
    @IBOutlet private weak var titleLabel: UILabel!

    /// Shows the dateCreated and order number.
    ///
    @IBOutlet private weak var subtitleLabel: UILabel!

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
        subtitleLabel.text = viewModel.subtitle

        display(presentation: viewModel.presentation)
    }

    /// Displays the specified OrderStatus, and applies the right Label Style
    ///
    private func display(presentation: SummaryTableViewCellViewModel.OrderStatusPresentation) {
        paymentStatusLabel.applyStyle(for: presentation.style)
        paymentStatusLabel.text = presentation.title
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
        subtitleLabel.applyFootnoteStyle()
        subtitleLabel.accessibilityIdentifier = "summary-table-view-cell-created-label"
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


// MARK: - VoiceOver
//
private extension SummaryTableViewCell {
    func configureIconForVoiceOver() {
        updateStatusButton.accessibilityLabel = NSLocalizedString("Update Order Status",
                                                                  comment: "Accessibility label for the button to update the order status in Order Details")
        updateStatusButton.accessibilityTraits = .button
        updateStatusButton.accessibilityHint = NSLocalizedString("Opens a list of available statuses.",
                                                                 comment: "Accessibility hint for the button to update the order status")
    }
}

// MARK: - Localization

private extension SummaryTableViewCellViewModel {
    enum Localization {
        static let guestName: String = NSLocalizedString("Guest",
                                                         comment: "In Order Details, the name of the billed person when there are no name and last name.")
    }
}
