import Foundation
import struct Networking.Booking

extension BookingDetailsViewModel {
    struct HeaderContent: Hashable {
        static let dateFormatter = {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd/MM/yyyy, hh:mm a"
            return dateFormatter
        }()

        let bookingDate: String
        let serviceName: String
        let customerName: String
        let status: [Status]

        init(_ booking: Booking) {
            bookingDate = Self.dateFormatter.string(from: booking.startDate)
            serviceName = "Women's Haircut"
            customerName = "Margarita Nikolaevna"
            status = [.paid, .booked]
        }
    }
}
