import Foundation
import Yosemite

struct SummaryTableViewCellViewModel {
    struct OrderStatusPresentation {
        let style: OrderStatusEnum
        let title: String
    }

    private let billingAddress: Address?
    private let dateCreated: Date
    private let salesChannel: String?

    let presentation: OrderStatusPresentation

    private let calendar: Calendar
    private let order: Order

    init(order: Order,
         status: OrderStatus?,
         calendar: Calendar = .current) {
        self.order = order

        billingAddress = order.billingAddress
        dateCreated = order.dateCreated
        salesChannel = order.createdVia

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
        formatter.timeZone = .siteTimezone
        return formatter.string(from: dateCreated)
    }

    /// Textual representation of the sales channel
    ///
    var formattedSalesChannel: String? {
        order.salesChannel?.description
    }
}

private extension SummaryTableViewCellViewModel {
    enum Localization {
        static let guestName: String = NSLocalizedString("SummaryTableViewCellViewModel.guestName",
                                                         value: "Guest",
                                                         comment: "In Order Details, the name of the billed person when there are no name and last name.")
    }
}
