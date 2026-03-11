import Foundation
import struct Yosemite.Booking
import enum Yosemite.BookingPaymentStatus

extension Booking {
    var productName: String? {
        orderInfo?.productInfo?.name
    }

    var customerName: String {
        guard let name = orderInfo?.customerInfo?.billingAddress.fullName else {
            return Localization.guest
        }
        return name.isEmpty ? Localization.guest : name
    }

    var isPaid: Bool {
        paymentStatusBadge == .paid || paymentStatusBadge == .partiallyRefunded
    }

    var hasAssociatedOrder: Bool {
        return orderID > 0
    }

    private enum Localization {
        static let guest = NSLocalizedString(
            "bookings.guest",
            value: "Guest",
            comment: "Displayed name on the booking list when no customer is associated with a booking."
        )
    }
}
