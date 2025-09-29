import Foundation
import struct Networking.Booking

extension BookingDetailsViewModel {
    struct HeaderContent: Hashable {
        let bookingDate: String
        let serviceName: String
        let customerName: String
        let status: [Status]

        init(_ booking: Booking) {
            bookingDate = booking.startDate.formatted(.dateTime
                .month(.twoDigits)
                .day(.twoDigits)
                .year(.defaultDigits)
                .hour(.twoDigits(amPM: .abbreviated))
                .minute(.twoDigits)
            )
            serviceName = "Women's Haircut"
            customerName = "Margarita Nikolaevna"
            status = [.booked, .payAtLocation]
        }
    }
}
