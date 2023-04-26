import UIKit
import Yosemite
import WooFoundation
import SwiftUI

/// The ViewModel for `OrderSubscriptionTableViewCell`.
///
struct OrderSubscriptionTableViewCellViewModel {
    struct SubscriptionStatusPresentation {
        let backgroundColor: UIColor
        let title: String
    }

    /// The subscription to display in the cell.
    ///
    private let subscription: Subscription

    /// The store's currency settings. Used to format the subscription price.
    ///
    private let currencySettings: CurrencySettings

    /// The current device timezone. Used to format the subscription dates.
    ///
    private let timeZone: TimeZone

    /// The current device calendar. Used to format the subscription dates.
    ///
    private let calendar: Calendar

    init(subscription: Subscription,
         timeZone: TimeZone = .current,
         calendar: Calendar = .current,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings) {
        self.subscription = subscription
        self.currencySettings = currencySettings
        self.timeZone = timeZone
        self.calendar = calendar
    }

    /// The subscription title with the subscription ID. Example: "Subscription #123"
    ///
    var subscriptionTitle: String {
        String.localizedStringWithFormat(Localization.titleFormat, subscription.subscriptionID)
    }

    /// The subscription start and end dates. Example: “Jan 31 - Apr 25, 2023”
    ///
    var subscriptionDates: String {
        subscription.startDate.formatAsRange(with: subscription.endDate, timezone: timeZone, calendar: calendar)
    }

    /// The subscription price, with the total, billing interval, and billing period. Example: "$60.00 / 2 months"
    ///
    var subscriptionPrice: String {
        let currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        guard subscription.total.isNotEmpty, let formattedPrice = currencyFormatter.formatAmount(subscription.total) else {
            return ""
        }

        let billingFrequency = {
            switch subscription.billingInterval {
            case "1":
                return subscription.billingPeriod.descriptionSingular
            default:
                return "\(subscription.billingInterval) \(subscription.billingPeriod.descriptionPlural)"
            }
        }()

        return String.localizedStringWithFormat(Localization.priceFormat, formattedPrice, billingFrequency)
    }

    /// The status badge color and text
    ///
    var statusPresentation: SubscriptionStatusPresentation {
        .init(backgroundColor: Constants.backgroundColor(for: subscription.status), title: Localization.statusLabel(for: subscription.status))
    }
}

// MARK: - OrderSubscriptionTableViewCell
//
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

    /// Shows the subscription price.
    ///
    @IBOutlet private weak var priceLabel: UILabel!

    func configure(_ viewModel: OrderSubscriptionTableViewCellViewModel) {
        dateLabel.text = viewModel.subscriptionDates
        titleLabel.text = viewModel.subscriptionTitle
        priceLabel.text = viewModel.subscriptionPrice

        display(presentation: viewModel.statusPresentation)
    }

    /// Displays the correct title and background color for the specified `SubscriptionStatus`.
    ///
    private func display(presentation: OrderSubscriptionTableViewCellViewModel.SubscriptionStatusPresentation) {
        statusLabel.backgroundColor = presentation.backgroundColor
        statusLabel.text = presentation.title
    }

    // MARK: - Overridden Methods

    override func awakeFromNib() {
        super.awakeFromNib()

        configureBackground()
        configureLabels()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        statusLabel.layer.borderColor = UIColor.clear.cgColor
    }
}


// MARK: - Private

private extension OrderSubscriptionTableViewCell {

    func configureBackground() {
        applyDefaultBackgroundStyle()
    }

    /// Setup: Labels
    ///
    func configureLabels() {
        titleLabel.applyBodyStyle()
        dateLabel.applyFootnoteStyle()
        priceLabel.applyBodyStyle()
        configureStatusLabel()
    }

    func configureStatusLabel() {
        statusLabel.applyPaddedLabelDefaultStyles()
        statusLabel.textColor = .black
        statusLabel.layer.masksToBounds = true
        statusLabel.layer.borderWidth = Constants.StatusLabel.borderWidth
    }

    enum Constants {
        enum StatusLabel {
            static let borderWidth = CGFloat(0.0)
        }
    }
}

// MARK: - Localization

private extension OrderSubscriptionTableViewCellViewModel {
    enum Localization {
        static let titleFormat: String = NSLocalizedString("Subscription #%d",
                                                           comment: "Subscription title with subscription number. Reads like: 'Subscription #123'")
        static let priceFormat = NSLocalizedString("%1$@ / %2$@",
                                                   comment: "Description of the subscription price for a product, with the price and billing frequency. " +
                                                   "Reads like: '$60.00 / 2 months'.")

        static func statusLabel(for status: SubscriptionStatus) -> String {
            switch status {
            case .active:
                return NSLocalizedString("Active", comment: "Display label for the subscription status type")
            case .cancelled:
                return NSLocalizedString("Cancelled", comment: "Display label for the subscription status type")
            case .expired:
                return NSLocalizedString("Expired", comment: "Display label for the subscription status type")
            case .onHold:
                return NSLocalizedString("On Hold", comment: "Display label for the subscription status type")
            case .pending:
                return NSLocalizedString("Pending", comment: "Display label for the subscription status type")
            case .pendingCancel:
                return NSLocalizedString("Pending Cancel", comment: "Display label for the subscription status type")
            case .custom(let payload):
                return payload
            }
        }
    }
    enum Constants {
        static func backgroundColor(for status: SubscriptionStatus) -> UIColor {
            switch status {
            case .pending, .pendingCancel, .custom:
                return .gray(.shade5)
            case .onHold:
                return .withColorStudio(.orange, shade: .shade5)
            case .active:
                return .withColorStudio(.green, shade: .shade5)
            case .cancelled, .expired:
                return .withColorStudio(.red, shade: .shade5)
            }
        }
    }
}
