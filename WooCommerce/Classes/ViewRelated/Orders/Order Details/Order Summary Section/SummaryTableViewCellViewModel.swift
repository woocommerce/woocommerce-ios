import Foundation
import Yosemite

struct SummaryTableViewCellViewModel {
    struct OrderStatusPresentation {
        let style: OrderStatusEnum
        let title: String
    }

    private let billingAddress: Address?
    private let dateCreated: Date
    private(set) var salesChannel: String?

    let presentation: OrderStatusPresentation

    /// Whether the edit status button should be displayed.
    let isEditButtonVisible: Bool

    private let calendar: Calendar

    init(order: Order,
         status: OrderStatus?,
         isEditButtonVisible: Bool = true,
         calendar: Calendar = .current) {

        billingAddress = order.billingAddress
        dateCreated = order.dateCreated
        salesChannel = order.salesChannel?.description

        presentation = OrderStatusPresentation(
            style: status?.status ?? order.status,
            title: status?.name ?? order.status.rawValue
        )

        self.isEditButtonVisible = isEditButtonVisible
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
}

private extension SummaryTableViewCellViewModel {
    enum Localization {
        static let guestName: String = NSLocalizedString("SummaryTableViewCellViewModel.guestName",
                                                         value: "Guest",
                                                         comment: "In Order Details, the name of the billed person when there are no name and last name.")
    }
}
