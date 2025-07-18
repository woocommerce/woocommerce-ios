import Foundation

/// Shared localization for `OrderListCellViewModel` between `WooCommerce` and `Woo Watch App` targets
enum OrderListCellViewModelLocalization {
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
