import Foundation
import class WooFoundationCore.CurrencyFormatter
import struct Networking.Booking
import struct Networking.BookingOrderInfo
import struct Networking.BookingResource

struct POSBookingMapper {
    private let currencyFormatter: CurrencyFormatter

    init(currencyFormatter: CurrencyFormatter) {
        self.currencyFormatter = currencyFormatter
    }

    func map(booking: Booking,
             orderInfo: BookingOrderInfo?,
             resource: BookingResource?) -> POSBooking {
        let customerName: String = {
            if let customer = orderInfo?.customerInfo {
                let first = customer.billingAddress.firstName
                let last = customer.billingAddress.lastName
                let fullName = [first, last].filter { !$0.isEmpty }.joined(separator: " ")
                return fullName.isEmpty ? Localization.guest : fullName
            }
            return Localization.guest
        }()

        let serviceName = orderInfo?.productInfo?.name ?? ""

        let formattedAmount = currencyFormatter.formatAmount(booking.cost, with: booking.currency) ?? booking.cost

        let orderID: Int64? = booking.orderID != 0 ? booking.orderID : nil

        return POSBooking(
            id: booking.bookingID,
            customerName: customerName,
            serviceName: serviceName,
            startDate: booking.startDate,
            endDate: booking.endDate,
            formattedAmount: formattedAmount,
            bookingStatus: booking.bookingStatus,
            attendanceStatus: booking.attendanceStatus,
            paymentStatus: booking.paymentStatus,
            orderID: orderID,
            resourceName: resource?.name
        )
    }
}

private enum Localization {
    static let guest = NSLocalizedString(
        "pos.booking.guestCustomerName",
        value: "Guest",
        comment: "Displayed as the customer name when a booking has no linked customer."
    )
}
