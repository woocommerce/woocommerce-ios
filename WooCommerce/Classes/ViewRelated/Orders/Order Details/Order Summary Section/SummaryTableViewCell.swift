import UIKit
import Yosemite
import Gridicons

final class SummaryTableViewCell: UITableViewCell {

    /// Label: Title
    ///
    @IBOutlet private weak var titleLabel: UILabel!

    /// Shows the dateCreated and order number.
    ///
    @IBOutlet private weak var subtitleLabel: UILabel!

    /// Shows the sales channel if appropiate, at the moment only Point of Sale
    ///
    @IBOutlet private weak var salesChannelLabel: PaddedLabel!

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
        salesChannelLabel.text = viewModel.salesChannel
        salesChannelLabel.isHidden = (salesChannelLabel.text == nil)
        updateStatusButton.isHidden = !viewModel.isEditButtonVisible
        display(presentation: viewModel.presentation)
    }

    /// Displays the specified OrderStatus, and applies the right Label Style
    ///
    private func display(presentation: SummaryTableViewCellViewModel.OrderStatusPresentation) {
        paymentStatusLabel.applyStyle(for: presentation.style)
        paymentStatusLabel.text = presentation.title
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        configureBackground()
        configureLabels()
        configureIcon()
    }

    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        updateDefaultBackgroundConfiguration(using: state)
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
        configureDefaultBackgroundConfiguration()
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

        if ServiceLocator.featureFlagService.isFeatureFlagEnabled(.pointOfSaleOrdersi1) {
            salesChannelLabel.isHidden = false
            configureSalesChannelLabel()
        } else {
            salesChannelLabel.isHidden = true
        }
    }

    func configureIcon() {
        updateStatusButton.applyIconButtonStyle(icon: .pencilImage)

        updateStatusButton.addTarget(self, action: #selector(editWasTapped), for: .touchUpInside)

        configureIconForVoiceOver()
    }

    func configureSalesChannelLabel() {
        salesChannelLabel.numberOfLines = 1
        salesChannelLabel.textInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        salesChannelLabel.applySalesChannelStyle()
        salesChannelLabel.accessibilityIdentifier = "summary-table-view-cell-sales-channel-label"
    }

    @objc func editWasTapped() {
        onEditTouchUp?()
    }
}

private extension SummaryTableViewCell {
    func configureIconForVoiceOver() {
        updateStatusButton.accessibilityLabel = NSLocalizedString("Update Order Status",
                                                                  comment: "Accessibility label for the button to update the order status in Order Details")
        updateStatusButton.accessibilityTraits = .button
        updateStatusButton.accessibilityHint = NSLocalizedString("Opens a list of available statuses.",
                                                                 comment: "Accessibility hint for the button to update the order status")
    }
}
