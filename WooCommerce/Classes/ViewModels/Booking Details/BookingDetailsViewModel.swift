import Foundation
import WooFoundation
import struct Networking.Booking

extension BookingDetailsViewModel {
    enum Status {
        case booked, paid
    }
}

extension BookingDetailsViewModel {
    struct Section: Identifiable {
        var id: String {
            return content.id
        }

        let headerText: String?
        let footerText: String?
        let content: SectionContent

        init(
            headerText: String? = nil,
            footerText: String? = nil,
            content: SectionContent
        ) {
            self.headerText = headerText
            self.footerText = footerText
            self.content = content
        }
    }

    enum SectionContent: Identifiable {
        var id: String {
            switch self {
            case .header:
                return "header"
            case .appointmentDetails:
                return "appointmentDetails"
            }
        }

        case header(HeaderContent)
        case appointmentDetails(AppointmentDetailsContent)
//        case attendance(AttendanceContent)
//        case payment(PaymentContent)
//        case customer(CustomerContent)
//        case teamMember(TeamMemberContent)
    }
}

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

        let rows: [Row]

        struct Row: Identifiable {
            let title: String
            let value: String

            var id: String {
                return title
            }
        }

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
//    // MARK: - Payment Details
//    let servicesCost: String
//    let tax: String
//    let total: String
//    let paid: String
//
//    // MARK: - Customer Details
//    var customerEmail: String {
//        // This will be fetched from the customer details later
//        return "margarita.n@mail.com"
//    }
//
//    var customerPhone: String {
//        // This will be fetched from the customer details later
//        return "+1742582943798"
//    }
//
//    var billingAddress: String {
//        // This will be fetched from the customer details later
//        return "238 Willow Creek Drive\nMontgomery\nAL 36109"
//    }

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

        // This will be assigned later
//        servicesCost = "$62.68"
//        tax = "$7.32"
//        total = booking.cost
//        paid = booking.cost
    }
}
