import Foundation
import Yosemite

// MARK: - View Model for individual cells on the Order List screen
//
struct OrderListCellViewModel {
    private let order: Order
    private let orderStatus: OrderStatus?

    private let currencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)

    init(order: Order, status: OrderStatus?) {
        self.order = order
        orderStatus = status
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
