import Foundation
import struct Networking.Booking

extension BookingDetailsViewModel {
    struct HeaderContent: Hashable {
        let bookingDate: String
        let serviceAndCustomerLine: String
        let status: [Status]

        init(_ booking: Booking) {
            bookingDate = booking.startDate.formatted(
                date: .numeric,
                time: .shortened
            )

            /// Temporary hardcode
            serviceAndCustomerLine = [
                "Women's Haircut",
                "Margarita Nikolaevna"
            ].joined(separator: Constants.dotSeparator)

            status = [.booked, .payAtLocation]
        }
    }
}

private extension BookingDetailsViewModel {
    enum Constants {
        static let dotSeparator: String = " • "
    }
}
