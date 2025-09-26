import Foundation
import struct Networking.Booking

extension BookingDetailsViewModel {
    struct PaymentContent {
    }

    struct CustomerContent {
    }

    struct TeamMemberContent {
    }
}

final class BookingDetailsViewModel: ObservableObject {
    let sections: [Section]

    init(booking: Booking) {
        let headerSection = Section.init(
            content: .header(HeaderContent(booking))
        )

        let appointmentDetailsSection = Section(
            header: .title(Localization.appointmentDetailsSectionHeaderTitle.uppercased()),
            content: .appointmentDetails(AppointmentDetailsContent(booking))
        )

        let attendanceSection = Section(
            header: .empty,
            footerText: "Mark attendance to keep your reports accurate and spot booking trends.",
            content: .attendance(AttendanceContent())
        )

        sections = [
            headerSection,
            appointmentDetailsSection,
            attendanceSection
        ]
    }
}

private extension BookingDetailsViewModel {
    enum Localization {
        static let appointmentDetailsSectionHeaderTitle = NSLocalizedString(
            "BookingDetailsView.appointmentDetails.headerTitle",
            value: "Appointment Details",
            comment: "Header title for the 'Appointment Details' section in the booking details screen."
        )
    }
}
