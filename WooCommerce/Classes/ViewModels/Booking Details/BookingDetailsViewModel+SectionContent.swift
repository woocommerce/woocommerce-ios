import Foundation

extension BookingDetailsViewModel {
    enum SectionContent {
        case header(HeaderContent)
        case appointmentDetails(AppointmentDetailsContent)
        case attendance(AttendanceContent)
        case payment(PaymentContent)
        case customer(CustomerContent)
        case teamMember(TeamMemberContent)
    }
}

extension BookingDetailsViewModel.SectionContent: Identifiable {
    var id: String {
        switch self {
        case .header:
            return "header"
        case .appointmentDetails:
            return "appointmentDetails"
        case .attendance:
            return "attendance"
        case .payment:
            return "payment"
        case .customer:
            return "customer"
        case .teamMember:
            return "teamMember"
        }
    }
}
