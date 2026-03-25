import Foundation
import Yosemite

extension BookingDetailsViewModel {
    final class AppointmentDetailsContent: ObservableObject {
        struct Row: Identifiable {
            let title: String
            let value: String
            let isLoading: Bool

            var id: String {
                return title
            }

            init(title: String, value: String, isLoading: Bool = false) {
                self.title = title
                self.value = value
                self.isLoading = isLoading
            }
        }

        @Published private(set) var rows: [Row] = []

        private static let shimmeringPlaceholder = String(repeating: "X", count: 20)

        func update(with booking: Booking,
                    resource: BookingResource?,
                    bookingLocation: String? = nil,
                    isLoadingResource: Bool = false,
                    isLoadingLocation: Bool = false) {
            let appointmentDate = booking.startDate.toString(dateStyle: .short, timeStyle: .none, timeZone: BookingListTab.utcTimeZone)
            let appointmentTimeFrame = [
                booking.startDate.toString(dateStyle: .none, timeStyle: .short, timeZone: BookingListTab.utcTimeZone),
                booking.endDate.toString(dateStyle: .none, timeStyle: .short, timeZone: BookingListTab.utcTimeZone)
            ].joined(separator: " - ")

            let resourceRow: Row? = {
                guard booking.resourceID > 0 else { return nil }
                let value = isLoadingResource ? Self.shimmeringPlaceholder : (resource?.name ?? "-")
                return Row(title: Localization.appointmentDetailsAssignedStaffTitle,
                           value: value,
                           isLoading: isLoadingResource)
            }()

            let locationValue: String = {
                if isLoadingLocation {
                    return Self.shimmeringPlaceholder
                }
                guard let location = bookingLocation, !location.isEmpty else {
                    return "-"
                }
                return location
            }()

            rows = [
                Row(title: Localization.appointmentDetailsDateRowTitle, value: appointmentDate),
                Row(title: Localization.appointmentDetailsTimeRowTitle, value: appointmentTimeFrame),
                resourceRow,
                Row(title: Localization.appointmentDetailsLocationTitle, value: locationValue, isLoading: isLoadingLocation),
                Row(
                    title: Localization.appointmentDetailsDurationTitle,
                    value: Self.formatDuration(
                        from: booking.startDate,
                        to: booking.endDate
                    )
                )
            ].compactMap { $0 }
        }
    }
}

private extension BookingDetailsViewModel.AppointmentDetailsContent {
    static let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .short
        formatter.allowedUnits = [.hour, .minute]
        return formatter
    }()

    static func formatDuration(from startDate: Date, to endDate: Date) -> String {
        durationFormatter.string(from: startDate, to: endDate) ?? ""
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

        static let appointmentDetailsAssignedStaffTitle = NSLocalizedString(
            "BookingDetailsView.appointmentDetails.assignedStaff.title",
            value: "Assigned staff",
            comment: "Assigned staff row title in appointment details section in booking details view."
        )

        static let appointmentDetailsLocationTitle = NSLocalizedString(
            "BookingDetailsView.appointmentDetails.locationRow.title",
            value: "Location",
            comment: "Location row title in appointment details section in booking details view."
        )

        static let appointmentDetailsDurationTitle = NSLocalizedString(
            "BookingDetailsView.appointmentDetails.durationRow.title",
            value: "Duration",
            comment: "Duration row title in appointment details section in booking details view."
        )
    }
}
