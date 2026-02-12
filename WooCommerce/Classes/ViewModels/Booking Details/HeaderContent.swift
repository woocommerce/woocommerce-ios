import Foundation
import struct Yosemite.Booking
import struct Yosemite.BookingProductInfo
import struct Yosemite.Customer
import struct Yosemite.Address
import enum Yosemite.BookingAttendanceStatus
import enum Yosemite.BookingStatus

extension BookingDetailsViewModel {
    final class HeaderContent: ObservableObject {
        @Published private(set) var bookingDate: String = ""
        @Published private(set) var serviceLine: String = ""
        @Published private(set) var customerLine: String = ""
        @Published private(set) var statusBadge: BookingBadgeable = BookingStatus.unknown

        func update(with booking: Booking) {
            bookingDate = booking.startDate.toString(
                dateStyle: .short,
                timeStyle: .short,
                timeZone: BookingListTab.utcTimeZone
            )
            serviceLine = booking.productName ?? ""
            customerLine = booking.customerName
            statusBadge = booking.bookingItemHeaderStatusBadge
        }
    }
}
