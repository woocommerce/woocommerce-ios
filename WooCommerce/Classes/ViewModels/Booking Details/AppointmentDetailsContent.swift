import Foundation
import struct Networking.Booking

extension BookingDetailsViewModel {
    struct AppointmentDetailsContent {
        static let appointmentDateFormatter = {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEEE, dd MMMM yyyy"
            return dateFormatter
        }()

        static let appointmentTimeFrameFormatter = {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "hh:mm a"
            return dateFormatter
        }()

        struct Row: Identifiable {
            let title: String
            let value: String

            var id: String {
                return title
            }
        }

        let rows: [Row]

        init(_ booking: Booking) {
            let durationMinutes = Int(booking.endDate.timeIntervalSince(booking.startDate) / 60)
            let appointmentDate = Self.appointmentDateFormatter.string(from: booking.startDate)
            let appointmentTimeFrame = [
                Self.appointmentTimeFrameFormatter.string(from: booking.startDate),
                Self.appointmentTimeFrameFormatter.string(from: booking.endDate)
            ].joined(separator: " - ")

            rows = [
                Row(title: "Date", value: appointmentDate),
                Row(title: "Time", value: appointmentTimeFrame),
                Row(title: "Service", value: "Women's Haircut"),
                Row(title: "Quantity", value: "1"),
                Row(title: "Duration", value: String(durationMinutes)),
                Row(title: "Cost", value: booking.cost)
            ]
        }
    }
}
