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
        let billingAddress = orderInfo?.customerInfo?.billingAddress

        let customerName: String = {
            if let billingAddress {
                let fullName = [billingAddress.firstName, billingAddress.lastName]
                    .filter { !$0.isEmpty }
                    .joined(separator: " ")
                return fullName.isEmpty ? Localization.guest : fullName
            }
            return Localization.guest
        }()

        let serviceName = orderInfo?.productInfo?.name ?? ""

        let formattedAmount = currencyFormatter.formatAmount(booking.cost, with: booking.currency) ?? booking.cost

        let orderID: Int64? = booking.orderID != 0 ? booking.orderID : nil

        let formattedBillingAddress: String? = {
            guard let billingAddress else { return nil }
            let parts = [billingAddress.address1, billingAddress.city, billingAddress.state, billingAddress.postcode]
                .filter { !$0.isEmpty }
            return parts.isEmpty ? nil : parts.joined(separator: ", ")
        }()

        let location: String? = formattedBillingAddress

        let duration = Self.formatDuration(from: booking.startDate, to: booking.endDate)

        let formattedSubtotal = orderInfo?.paymentInfo.flatMap {
            currencyFormatter.formatAmount($0.subtotal, with: booking.currency)
        }
        let formattedTax = orderInfo?.paymentInfo.flatMap {
            currencyFormatter.formatAmount($0.totalTax, with: booking.currency)
        }

        return POSBooking(
            id: booking.bookingID,
            customerName: customerName,
            serviceName: serviceName,
            startDate: booking.startDate,
            endDate: booking.endDate,
            formattedAmount: formattedAmount,
            status: booking.bookingStatus,
            attendanceStatus: booking.attendanceStatus,
            orderID: orderID,
            resourceName: resource?.name,
            customerEmail: billingAddress?.email?.nilIfEmpty,
            customerPhone: billingAddress?.phone?.nilIfEmpty,
            billingAddress: formattedBillingAddress,
            customerNote: orderInfo?.customerInfo?.note?.nilIfEmpty,
            location: location,
            duration: duration,
            formattedSubtotal: formattedSubtotal,
            formattedTax: formattedTax
        )
    }

    static func formatDuration(from start: Date, to end: Date) -> String {
        let interval = end.timeIntervalSince(start)
        let totalMinutes = Int(interval / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 && minutes > 0 {
            return String(format: Localization.durationHoursAndMinutes, hours, minutes)
        } else if hours > 0 {
            return String(format: Localization.durationHours, hours)
        } else {
            return String(format: Localization.durationMinutes, max(minutes, 1))
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

private enum Localization {
    static let guest = NSLocalizedString(
        "pos.booking.guestCustomerName",
        value: "Guest",
        comment: "Displayed as the customer name when a booking has no linked customer."
    )

    static let durationMinutes = NSLocalizedString(
        "pos.booking.durationMinutes",
        value: "%d min",
        comment: "Booking duration in minutes, e.g. '60 min'. %d is the number of minutes."
    )

    static let durationHours = NSLocalizedString(
        "pos.booking.durationHours",
        value: "%dh",
        comment: "Booking duration in whole hours, e.g. '2h'. %d is the number of hours."
    )

    static let durationHoursAndMinutes = NSLocalizedString(
        "pos.booking.durationHoursAndMinutes",
        value: "%dh %dm",
        comment: "Booking duration in hours and minutes, e.g. '1h 30m'. First %d is hours, second %d is minutes."
    )
}
