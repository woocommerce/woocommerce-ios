import Foundation

#if canImport(Yosemite)
import Yosemite
#elseif canImport(NetworkingWatchOS)
import NetworkingWatchOS
#endif

#if canImport(WooFoundation)
import WooFoundation
#elseif canImport(WooFoundationWatchOS)
import WooFoundationWatchOS
#endif


// MARK: - View Model for individual cells on the Order List screen
//
struct OrderListCellViewModel {
    private let order: Order
    private let orderStatus: OrderStatus?
    private let currencyFormatter: CurrencyFormatter

    init(order: Order, status: OrderStatus?, currencySettings: CurrencySettings) {
        self.order = order
        self.orderStatus = status
        self.currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
    }

    /// For example, #560 Pamela Nguyen
    ///
    var title: String {
        let customerName: String = {
            if let fullName = order.billingAddress?.fullName, fullName.isNotEmpty {
                return fullName
            }
            return Localization.guestName
        }()

        return Localization.title(orderNumber: order.number, customerName: customerName)
    }

    /// The localized unabbreviated total which includes the currency.
    ///
    /// Example: $48,415,504.20
    ///
    var total: String? {
        return currencyFormatter.formatAmount(order.total, with: order.currency)
    }

    /// The value will only include the year if the `createdDate` is not from the current year.
    ///
    var dateCreated: String {
        let isSameYear = order.dateCreated.isSameYear(as: Date())
        let formatter: DateFormatter = isSameYear ? .monthAndDayFormatter : .mediumLengthLocalizedDateFormatter
        formatter.timeZone = .siteTimezone
        return formatter.string(from: order.dateCreated)
    }

    /// Status of the order
    ///
    var status: OrderStatusEnum {
        return orderStatus?.status ?? order.status
    }

    /// Textual representation of the status
    ///
    /// There are unsupported extensions with even more statuses available.
    /// So if orderStatus doesn't have a name, let's use the order.status to display those as slugs.
    var statusString: String {
        return orderStatus?.name ?? order.status.rawValue
    }

#if !os(watchOS)
    /// Accessory view that renders the cell's disclosure indicator
    ///
    var accessoryView: UIImageView? {
        guard let image = UIImage(systemName: "chevron.forward") else {
            return nil
        }
        let accessoryView = UIImageView(image: image, highlightedImage: nil)
        accessoryView.tintColor = .tertiaryLabel
        return accessoryView
    }
#endif
}

// MARK: - Constants

private extension OrderListCellViewModel {
    enum Localization {
        static func title(orderNumber: String, customerName: String) -> String {
            let format = NSLocalizedString("#%@ %@", comment: "In Order List,"
                + " the pattern to show the order number. For example, “#123456”."
                + " The %@ placeholder is the order number.")

            return String.localizedStringWithFormat(format, orderNumber, customerName)
        }

        static let guestName = NSLocalizedString("Guest", comment: "In Order List, the name of the billed person when there are no first and last name.")
    }
}
