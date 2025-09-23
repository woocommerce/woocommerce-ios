import Foundation
import WooFoundation
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
            headerText: "Appointment Details".uppercased(),
            content: .appointmentDetails(AppointmentDetailsContent(booking))
        )

        sections = [
            headerSection,
            appointmentDetailsSection
        ]
    }
}
