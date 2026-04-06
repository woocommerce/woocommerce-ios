import Foundation
import class WooFoundationCore.CurrencyFormatter
import struct Networking.Booking
import struct Networking.BookingOrderInfo
import struct Networking.BookingResource

struct POSBookingMapper {
    private let currencyFormatter: CurrencyFormatter
    private let siteSettings: [SiteSetting]

    init(currencyFormatter: CurrencyFormatter, siteSettings: [SiteSetting] = []) {
        self.currencyFormatter = currencyFormatter
        self.siteSettings = siteSettings
    }

    func map(booking: Booking,
             orderInfo: BookingOrderInfo?,
             resource: BookingResource?,
             order: POSOrder) -> POSBooking {
        let billingAddress = orderInfo?.customerInfo?.billingAddress

        let customerName: String? = {
            guard let billingAddress else { return nil }
            let fullName = [billingAddress.firstName, billingAddress.lastName]
                .filter { !$0.isEmpty }
                .joined(separator: " ")
            return fullName.isEmpty ? nil : fullName
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

        // TODO: The source for booking location is still undecided.
        // Using the store address from POS Settings as a temporary placeholder.
        let location: String? = {
            let siteAddress = SiteAddress(siteSettings: siteSettings)
            let parts = [siteAddress.address, siteAddress.city, siteAddress.state, siteAddress.postalCode]
                .filter { !$0.isEmpty }
            return parts.isEmpty ? nil : parts.joined(separator: ", ")
        }()

        let duration = Self.formatDuration(from: booking.startDate, to: booking.endDate)

        let formattedSubtotal = orderInfo?.paymentInfo.flatMap {
            currencyFormatter.formatAmount($0.subtotal, with: booking.currency)
        }
        let formattedTax = orderInfo?.paymentInfo.flatMap {
            currencyFormatter.formatAmount($0.totalTax, with: booking.currency)
        }

        return POSBooking(
            id: booking.bookingID,
            customerID: booking.customerID,
            userID: booking.userID,
            customerName: customerName,
            serviceName: serviceName,
            startDate: booking.startDate,
            endDate: booking.endDate,
            formattedAmount: formattedAmount,
            status: booking.bookingStatus,
            attendanceStatus: booking.attendanceStatus,
            orderID: orderID,
            resourceName: resource?.name,
            resourceImageURL: resource?.imageURL,
            customerEmail: billingAddress?.email?.nilIfEmpty,
            customerPhone: billingAddress?.phone?.nilIfEmpty,
            billingAddress: formattedBillingAddress,
            customerNote: orderInfo?.customerInfo?.note?.nilIfEmpty,
            bookingNote: booking.note.nilIfEmpty,
            location: location,
            duration: duration,
            formattedSubtotal: formattedSubtotal,
            formattedTax: formattedTax,
            order: order
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
