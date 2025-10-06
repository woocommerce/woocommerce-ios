import Foundation
import struct Networking.Booking
import struct Networking.Customer
import struct Networking.Address
import WooFoundation
import Yosemite
import SwiftUI // Added for withAnimation

@MainActor
final class BookingDetailsViewModel: ObservableObject {
    private let stores: StoresManager

    let navigationTitle: String

    private let booking: Booking
    private let customerContent = CustomerContent()

    @Published private(set) var sections: [Section] = []

    init(booking: Booking, stores: StoresManager = ServiceLocator.stores) {
        self.booking = booking
        self.stores = stores
        navigationTitle = Self.navigationTitle(for: booking)
        setupSections()
    }

    private func setupSections() {
        let headerSection = Section(
            content: .header(HeaderContent(booking))
        )

        let appointmentDetailsSection = Section(
            header: .title(Localization.appointmentDetailsSectionHeaderTitle.uppercased()),
            content: .appointmentDetails(AppointmentDetailsContent(booking))
        )

        let attendanceSection = Section(
            header: .title(Localization.attendanceSectionHeaderTitle.uppercased()),
            footerText: Localization.attendanceSectionFooterText,
            content: .attendance(AttendanceContent())
        )

        let paymentSection = Section(
            header: .title(Localization.paymentSectionHeaderTitle.uppercased()),
            content: .payment(PaymentContent(booking: booking))
        )

        let bookingNotes = Section(
            header: .title(Localization.bookingNotesSectionHeaderTitle.uppercased()),
            content: .bookingNotes
        )

        sections = [
            headerSection,
            appointmentDetailsSection,
            attendanceSection,
            paymentSection,
            bookingNotes
        ]
    }
}

// MARK: Syncing

extension BookingDetailsViewModel {
    func syncData() async {
        await syncCustomer()
    }
}

private extension BookingDetailsViewModel {
    func syncCustomer() async {
        guard shouldSyncCustomer else {
            return
        }

        do {
            let fetchedCustomer = try await retrieveCustomer()
            customerContent.update(with: fetchedCustomer)

            let customerSection = Section(
                header: .title(Localization.customerSectionHeaderTitle.uppercased()),
                content: .customer(customerContent)
            )
            withAnimation {
                sections.insert(customerSection, at: 2)
            }
        } catch {
            DDLogError("⛔️ Error synchronizing Customer for Booking: \(error)")
        }
    }

    func retrieveCustomer() async throws -> Customer {
        try await withCheckedThrowingContinuation { continuation in
            let action = CustomerAction.retrieveCustomer(
                siteID: booking.siteID,
                customerID: booking.customerID
            ) { result in
                switch result {
                case .success(let customer):
                    continuation.resume(returning: customer)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            stores.dispatch(action)
        }
    }

    /// Returns true when the `customerID` is non-zero and customer section doesn't exist
    var shouldSyncCustomer: Bool {
        return booking.customerID > 0 && !sections.contains(where: {
            if case .customer = $0.content {
                return true
            }
            return false
        })
    }
}

private extension BookingDetailsViewModel {
    static func navigationTitle(for booking: Booking) -> String {
        let titleFormat = NSLocalizedString(
            "BookingDetailsView.navTitle",
            value: "Booking #%1$d",
            comment: "Booking Details screen nav bar title. %1$d is a placeholder for the booking ID."
        )
        return String(format: titleFormat, booking.bookingID)
    }
}

private extension BookingDetailsViewModel {
    enum Localization {
        static let appointmentDetailsSectionHeaderTitle = NSLocalizedString(
            "BookingDetailsView.appointmentDetails.headerTitle",
            value: "Appointment Details",
            comment: "Header title for the 'Appointment Details' section in the booking details screen."
        )

        static let attendanceSectionHeaderTitle = NSLocalizedString(
            "BookingDetailsView.attendance.headerTitle",
            value: "Attendance",
            comment: "Header title for the 'Attendance' section in the booking details screen."
        )

        static let customerSectionHeaderTitle = NSLocalizedString(
            "BookingDetailsView.customer.headerTitle",
            value: "Customer",
            comment: "Header title for the 'Customer' section in the booking details screen."
        )

        static let attendanceSectionFooterText = NSLocalizedString(
            "BookingDetailsView.attendance.footerText",
            value: "Mark attendance to keep your reports accurate and spot booking trends.",
            comment: "Footer text for the 'Attendance' section in the booking details screen."
        )

        static let paymentSectionHeaderTitle = NSLocalizedString(
            "BookingDetailsView.payment.headerTitle",
            value: "Payment",
            comment: "Header title for the 'Payment' section in the booking details screen."
        )

        static let bookingNotesSectionHeaderTitle = NSLocalizedString(
            "BookingDetailsView.bookingNotes.headerTitle",
            value: "Booking notes",
            comment: "Header title for the 'Booking notes' section in the booking details screen."
        )
    }
}
