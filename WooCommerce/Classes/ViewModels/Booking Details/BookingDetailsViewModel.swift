import Foundation
import WooFoundation
import struct Networking.Booking

extension BookingDetailsViewModel {
    enum Status {
        case booked, paid
    }
}

private extension BookingDetailsViewModel {
    static let dateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy, hh:mm a"
        return dateFormatter
    }()

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
}

final class BookingDetailsViewModel: ObservableObject {

    init(booking: Booking) {
        bookingDate = Self.dateFormatter.string(from: booking.startDate)

        // This will be assigned later
        serviceName = "Women's Haircut"
        customerName = "Margarita Nikolaevna"
        service = "Women's Haircut"
        status = [.paid, .booked]
        quantity = 1
        servicesCost = "$62.68"
        tax = "$7.32"

        appointmentDate = Self.appointmentDateFormatter.string(from: booking.startDate)
        appointmentTimeFrame = [
            Self.appointmentTimeFrameFormatter.string(from: booking.startDate),
            Self.appointmentTimeFrameFormatter.string(from: booking.endDate)
        ].joined(separator: " - ")
        durationMinutes = Int(booking.endDate.timeIntervalSince(booking.startDate) / 60)

        cost = booking.cost
        total = booking.cost
        paid = booking.cost
    }

    // MARK: - Header Properties
    let bookingDate: String
    let serviceName: String
    let customerName: String
    let status: [Status]

    // MARK: - Appointment Details
    let appointmentDate: String
    let appointmentTimeFrame: String
    let service: String
    let quantity: Int
    let durationMinutes: Int
    let cost: String

    // MARK: - Payment Details
    let servicesCost: String
    let tax: String
    let total: String
    let paid: String

    // MARK: - Customer Details
    var customerEmail: String {
        // This will be fetched from the customer details later
        return "margarita.n@mail.com"
    }

    var customerPhone: String {
        // This will be fetched from the customer details later
        return "+1742582943798"
    }

    var billingAddress: String {
        // This will be fetched from the customer details later
        return "238 Willow Creek Drive\nMontgomery\nAL 36109"
    }

    // MARK: - Actions
    func rescheduleBooking() {
        // Placeholder for reschedule logic
    }

    func cancelBooking() {
        // Placeholder for cancel logic
    }

    func markAsPaid() {
        // Placeholder for mark as paid logic
    }

    func viewOrder() {
        // Placeholder for view order logic
    }
}
