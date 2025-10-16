import Foundation
import struct Yosemite.Booking
import struct Yosemite.Customer

extension BookingDetailsViewModel {
    final class HeaderContent: ObservableObject {
        let bookingDate: String
        let status: [Status]

        @Published var serviceAndCustomerLine: String

        init(_ booking: Booking, customerName: String? = nil) {
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

private extension BookingDetailsViewModel {
    enum Constants {
        static let dotSeparator: String = " • "
    }
}
