import Foundation
import struct Yosemite.Booking
import struct Yosemite.BookingProductInfo
import struct Yosemite.Customer
import struct Yosemite.Address

extension BookingDetailsViewModel {
    final class HeaderContent: ObservableObject {
        @Published private(set) var bookingDate: String = ""
        @Published private(set) var status: [Status] = []
        @Published private(set) var serviceAndCustomerLine: String = ""

        func update(with booking: Booking) {
            bookingDate = booking.startDate.toString(
                dateStyle: .short,
                timeStyle: .short,
                timeZone: BookingListTab.utcTimeZone
            )
            serviceAndCustomerLine = booking.summaryText
            status = [.booked, .payAtLocation]
        }
    }
}
