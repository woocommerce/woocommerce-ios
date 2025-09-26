import Foundation
import struct Networking.Booking

extension BookingDetailsViewModel {
    struct AppointmentDetailsContent {
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
            let appointmentDate = booking.startDate.formatted(date: .numeric, time: .omitted)
            let appointmentTimeFrame = [
                booking.startDate.formatted(date: .omitted, time: .shortened),
                booking.endDate.formatted(date: .omitted, time: .shortened)
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
