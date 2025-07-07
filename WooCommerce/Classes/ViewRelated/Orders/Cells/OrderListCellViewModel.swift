import Foundation

#if canImport(Yosemite)
import Yosemite
#elseif canImport(NetworkingCore)
import NetworkingCore
#endif

#if !os(watchOS)
import UIKit
#endif

import WooFoundationCore


// MARK: - View Model for individual cells on the Order List screen
//
struct OrderListCellViewModel {
    private let order: Order
    private let currencyFormatter: CurrencyFormatter

    /// Whether the order is eligible for displaying sales channel POS badge
    ///
    let isEligibleForDisplayingSalesChannelPOSBadge: Bool

    init(order: Order, currencySettings: CurrencySettings, isEligibleForDisplayingSalesChannelPOSBadge: Bool = false) {
        self.order = order
        self.currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        self.isEligibleForDisplayingSalesChannelPOSBadge = isEligibleForDisplayingSalesChannelPOSBadge
    }

    /// For example, #560 Pamela Nguyen
    ///
    var title: String {
        Localization.title(orderNumber: order.number, customerName: customerName)
    }

    /// For example, Pamela Nguyen
    ///
    var customerName: String {
        if let fullName = order.billingAddress?.fullName, fullName.isNotEmpty {
            return fullName
        }
        return Localization.guestName
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

    /// Time where the order was created
    ///
    var timeCreated: String {
        let formatter: DateFormatter = .timeFormatter
        formatter.timeZone = .siteTimezone
        return formatter.string(from: order.dateCreated)
    }

    /// Status of the order
    ///
    var status: OrderStatusEnum {
        return order.status
    }

    /// Textual representation of the status
    ///
    var statusString: String {
        return order.status.localizedName
    }

    /// Textual representation of the sales channel
    ///
    var salesChannel: String? {
        order.salesChannel?.description
    }

    /// The localized unabbreviated total for a given order item, which includes the currency.
    ///
    /// Example: $48,415,504.20
    ///
    func total(for orderItem: OrderItem) -> String {
        currencyFormatter.formatAmount(orderItem.total, with: order.currency) ?? "$\(orderItem.total)"
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

extension OrderListCellViewModel {
    enum Localization {
        static func title(orderNumber: String, customerName: String) -> String {
            let format = NSLocalizedString(
                "orderlistcellviewmodel.cell.title",
                value: "#%@ %@",
                comment: "In Order List,"
                + " the pattern to show the order number. For example, “#123456”."
                + " The %@ placeholder is the order number.")
            return String.localizedStringWithFormat(format, orderNumber, customerName)
        }
        static let guestName = NSLocalizedString(
            "orderlistcellviewmodel.customerName.guestName",
            value: "Guest",
            comment: "In Order List, the name of the billed person when there are no first and last name.")
    }
}
