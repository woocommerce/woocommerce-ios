import Foundation
import struct Networking.Booking

extension BookingDetailsViewModel {
    struct AttendanceContent {
    }

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
            headerText: Localization.appointmentDetailsSectionHeaderTitle.uppercased(),
            content: .appointmentDetails(AppointmentDetailsContent(booking))
        )

        sections = [
            headerSection,
            appointmentDetailsSection
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
