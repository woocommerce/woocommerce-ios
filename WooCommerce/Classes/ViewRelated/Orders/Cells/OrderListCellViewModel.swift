import Foundation
import Yosemite
import UIKit
import WooFoundationCore

// MARK: - View Model for individual cells on the Order List screen
//
struct OrderListCellViewModel {
    private let order: Order
    private let currencyFormatter: CurrencyFormatter
    private let isCIAB: Bool

    init(order: Order, currencySettings: CurrencySettings, isCIAB: Bool = false) {
        self.order = order
        self.currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        self.isCIAB = isCIAB
    }

    /// For example, #560 Pamela Nguyen
    ///
    var title: String {
        OrderListCellViewModelLocalization.title(orderNumber: order.number, customerName: customerName)
    }

    /// For example, Pamela Nguyen
    ///
    var customerName: String {
        if let fullName = order.billingAddress?.fullName, fullName.isNotEmpty {
            return fullName
        }
        return OrderListCellViewModelLocalization.guestName
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

    /// Status of the order (mapped for CIAB sites)
    ///
    var status: OrderStatusEnum {
        isCIAB ? CIABOrderStatusMapper.displayStatus(for: order.status) : order.status
    }

    /// Textual representation of the status (mapped for CIAB sites)
    ///
    var statusString: String {
        isCIAB ? CIABOrderStatusMapper.displayName(for: order.status) : order.status.localizedName
    }

    /// Sales channel
    ///
    var salesChannel: OrderSalesChannel? {
        order.salesChannel
    }

    /// The localized unabbreviated total for a given order item, which includes the currency.
    ///
    /// Example: $48,415,504.20
    ///
    func total(for orderItem: OrderItem) -> String {
        currencyFormatter.formatAmount(orderItem.total, with: order.currency) ?? "$\(orderItem.total)"
    }

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
}
