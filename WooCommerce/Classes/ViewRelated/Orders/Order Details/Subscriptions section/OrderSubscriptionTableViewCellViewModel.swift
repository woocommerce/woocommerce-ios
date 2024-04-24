import UIKit
import Yosemite
import WooFoundation

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
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false

        // Attempts to format the subscriptionID to remove localized grouping separators
        guard let formattedSubscriptionID = formatter.string(from: NSNumber(value: subscription.subscriptionID)) else {
            return String.localizedStringWithFormat(Localization.subscriptionTitle, subscription.subscriptionID)
        }
        return String.localizedStringWithFormat(Localization.formattedSubscriptionTitle, formattedSubscriptionID)
    }

    /// The subscription start and end dates. Example: “Jan 31 - Apr 25, 2023”
    ///
    var subscriptionDates: String {
        subscription.startDate.formatAsRange(with: subscription.endDate, timezone: timeZone, calendar: calendar)
    }

    /// The subscription billing interval, and period
    /// Eg: "Every 2 months"
    ///
    var subscriptionInterval: String {
        let billingFrequency = {
            switch subscription.billingInterval {
            case "1":
                return subscription.billingPeriod.descriptionSingular
            default:
                return subscription.billingPeriod.descriptionPlural
            }
        }()
        return String.localizedStringWithFormat(Localization.billingInterval, subscription.billingInterval, billingFrequency)
    }

    /// The formatted subscription price
    /// Eg: "$60.00"
    ///
    var subscriptionPrice: String {
        let currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        guard subscription.total.isNotEmpty, let formattedPrice = currencyFormatter.formatAmount(subscription.total) else {
            return ""
        }
        return String.localizedStringWithFormat(Localization.priceFormat, formattedPrice)
    }

    /// The status badge color and text
    ///
    var statusPresentation: SubscriptionStatusPresentation {
        .init(backgroundColor: Constants.backgroundColor(for: subscription.status), title: Localization.statusLabel(for: subscription.status))
    }
}

private extension OrderSubscriptionTableViewCellViewModel {
    enum Localization {
        static let subscriptionTitle: String = NSLocalizedString(
            "OrderSubscriptionTableViewCellViewModel.subscriptionTitle",
            value: "Subscription #%d",
            comment: "Subscription title with subscription number. Reads like: 'Subscription #123'")
        static let formattedSubscriptionTitle: String = NSLocalizedString(
            "OrderSubscriptionTableViewCellViewModel.formattedSubscriptionTitle",
            value: "Subscription #%1$@",
            comment: "Formatted subscription title with subscription number. Reads like: 'Subscription #123'")
        static let priceFormat = NSLocalizedString(
            "OrderSubscriptionTableViewCellViewModel.priceFormat",
            value: "%1$@",
            comment: "Description of the subscription price for a product. Reads like: '$60.00'.")
        static let billingInterval = NSLocalizedString(
            "OrderSubscriptionTableViewCellViewModel.billingInterval",
            value: "Every %1$@ %2$@",
            comment: "Description of the subscription billing interval for a product. Reads like: 'Every 2 months'.")

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
