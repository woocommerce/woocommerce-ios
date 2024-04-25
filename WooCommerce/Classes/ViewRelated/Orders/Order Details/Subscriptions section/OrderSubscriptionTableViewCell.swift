import UIKit
import Yosemite
import WooFoundation
import SwiftUI

final class OrderSubscriptionTableViewCell: UITableViewCell {
    /// Shows the start and end date for the subscription.
    ///
    @IBOutlet private weak var dateLabel: UILabel!

    /// Shows the subscription title with its ID.
    ///
    @IBOutlet private weak var titleLabel: UILabel!

    /// Shows the subscription status.
    ///
    @IBOutlet private weak var statusLabel: PaddedLabel!

    /// Shows the subscription interval.
    ///
    @IBOutlet private weak var intervalLabel: UILabel!

    /// Shows the subscription price.
    ///
    @IBOutlet private weak var priceLabel: UILabel!

    func configure(_ viewModel: OrderSubscriptionTableViewCellViewModel) {
        dateLabel.text = viewModel.subscriptionDates
        titleLabel.text = viewModel.subscriptionTitle
        priceLabel.text = viewModel.subscriptionPrice
        intervalLabel.text = viewModel.subscriptionInterval

        display(presentation: viewModel.statusPresentation)
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        configureBackground()
        configureLabels()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        statusLabel.layer.borderColor = UIColor.clear.cgColor
    }

    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        updateDefaultBackgroundConfiguration(using: state)
    }
}

private extension OrderSubscriptionTableViewCell {
    /// Displays the correct title and background color for the specified `SubscriptionStatus`.
    ///
    private func display(presentation: OrderSubscriptionTableViewCellViewModel.SubscriptionStatusPresentation) {
        statusLabel.backgroundColor = presentation.backgroundColor
        statusLabel.text = presentation.title
    }

    func configureBackground() {
        configureDefaultBackgroundConfiguration()
    }

    /// Setup: Labels
    ///
    func configureLabels() {
        titleLabel.applyBodyStyle()
        dateLabel.applyFootnoteStyle()
        priceLabel.applyBodyStyle()
        intervalLabel.applySecondaryBodyStyle()
        configureStatusLabel()
    }

    func configureStatusLabel() {
        statusLabel.applyPaddedLabelDefaultStyles()
        statusLabel.textColor = .black
        statusLabel.layer.masksToBounds = true
        statusLabel.layer.borderWidth = Constants.borderWidth
    }
}

private extension OrderSubscriptionTableViewCell {
    enum Constants {
        static let borderWidth: CGFloat = 0
    }
}
