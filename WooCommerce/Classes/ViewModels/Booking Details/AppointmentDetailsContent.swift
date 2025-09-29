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
                Row(title: Localization.appointmentDetailsDateRowTitle, value: appointmentDate),
                Row(title: Localization.appointmentDetailsTimeRowTitle, value: appointmentTimeFrame),
                Row(title: Localization.appointmentDetailsServiceTitle, value: "Women's Haircut"),
                Row(title: Localization.appointmentDetailsQuantityTitle, value: "1"),
                Row(title: Localization.appointmentDetailsDurationTitle, value: String(durationMinutes)),
                Row(title: Localization.appointmentDetailsCostTitle, value: booking.cost)
            ]
        }
    }
}

private extension BookingDetailsViewModel.AppointmentDetailsContent {
    enum Localization {
        static let appointmentDetailsDateRowTitle = NSLocalizedString(
            "BookingDetailsView.appointmentDetails.dateRow.title",
            value: "Date",
            comment: "Date row title in appointment details section in booking details view."
        )

        static let appointmentDetailsTimeRowTitle = NSLocalizedString(
            "BookingDetailsView.appointmentDetails.timeRow.title",
            value: "Time",
            comment: "Time row title in appointment details section in booking details view."
        )

        static let appointmentDetailsServiceTitle = NSLocalizedString(
            "BookingDetailsView.appointmentDetails.serviceRow.title",
            value: "Service",
            comment: "Service name row title in appointment details section in booking details view."
        )

        static let appointmentDetailsQuantityTitle = NSLocalizedString(
            "BookingDetailsView.appointmentDetails.quantityRow.title",
            value: "Quantity",
            comment: "Quantity row title in appointment details section in booking details view."
        )

        static let appointmentDetailsDurationTitle = NSLocalizedString(
            "BookingDetailsView.appointmentDetails.durationRow.title",
            value: "Duration",
            comment: "Duration row title in appointment details section in booking details view."
        )

        static let appointmentDetailsCostTitle = NSLocalizedString(
            "BookingDetailsView.appointmentDetails.costRow.title",
            value: "Cost",
            comment: "Cost row title in appointment details section in booking details view."
        )
    }
}
