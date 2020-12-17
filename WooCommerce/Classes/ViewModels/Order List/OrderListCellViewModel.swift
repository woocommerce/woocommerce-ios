import Foundation
import Yosemite

struct OrderListCellViewModel {
    let order: Order
    private let currencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)

    init(order: Order) {
        self.order = order
    }

    /// For example, #560 Pamela Nguyen
    ///
    var title: String {
        if let billingAddress = order.billingAddress, billingAddress.firstName.isNotEmpty || billingAddress.lastName.isNotEmpty {
            return Localization.title(orderNumber: order.number,
                                      firstName: billingAddress.firstName,
                                      lastName: billingAddress.lastName)
        }

        return Localization.title(orderNumber: order.number)
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

    var orderStatus: OrderStatusEnum {
        return order.status
    }
}

// MARK: - Constants

private extension OrderListCellViewModel {
    enum Localization {
        static func title(orderNumber: String, firstName: String, lastName: String) -> String {
            let format = NSLocalizedString("#%1$@ %2$@ %3$@", comment: "In Order List,"
                + " the pattern to show the order number and the full name. For example, “#123 John Doe”."
                + " The %1$@ is the order number. The %2$@ is the first name. The %3$@ is the last name.")

            return String.localizedStringWithFormat(format, orderNumber, firstName, lastName)
        }

        static func title(orderNumber: String) -> String {
            let format = NSLocalizedString("#%@ %@", comment: "In Order List,"
                + " the pattern to show the order number. For example, “#123456”."
                + " The %@ placeholder is the order number.")

            let guestName: String = NSLocalizedString("Guest", comment: "In Order List, the name of the billed person when there are no name and last name.")

            return String.localizedStringWithFormat(format, orderNumber, guestName)
        }
    }
}
