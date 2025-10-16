import Foundation
import Yosemite
import SwiftUI // Added for withAnimation

final class BookingDetailsViewModel: ObservableObject {
    private let stores: StoresManager
    private let resultsController: BookingDetailsResultsController

    private var booking: Booking {
        didSet {
            updateDisplayProperties(from: booking)
        }
    }
    private let headerContent: HeaderContent
    private let customerContent = CustomerContent()

    let navigationTitle: String
    @Published private(set) var sections: [Section] = []

    init(booking: Booking, stores: StoresManager = ServiceLocator.stores) {
        self.booking = booking
        self.stores = stores
        self.resultsController = BookingDetailsResultsController(booking: booking)
        self.headerContent = HeaderContent(booking)
        navigationTitle = Self.navigationTitle(for: booking)
        setupSections()
        configureResultsController()
        updateDisplayProperties(from: booking)
    }
}

// MARK: Private

private extension BookingDetailsViewModel {
    func setupSections() {
        let headerSection = Section(
            content: .header(headerContent)
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

    func configureResultsController() {
        resultsController.configure { [weak self] in
            if let newBooking = self?.resultsController.booking {
                self?.booking = newBooking
            }
        }
        if let newBooking = resultsController.booking {
            self.booking = newBooking
        }
    }

    func updateDisplayProperties(from booking: Booking) {
        if let billingAddress = booking.orderInfo?.customerInfo?.billingAddress {
            customerContent.update(with: billingAddress)
            headerContent.update(with: billingAddress)
            insertCustomerSectionIfAbsent()
        }
    }

    func insertCustomerSectionIfAbsent() {
        // Avoid adding if it already exists
        guard !sections.contains(where: { if case .customer = $0.content { return true } else { return false } }) else {
            return
        }

        let customerSection = Section(
            header: .title(Localization.customerSectionHeaderTitle.uppercased()),
            content: .customer(customerContent)
        )
        withAnimation {
            sections.insert(customerSection, at: 2)
        }
    }
}

// MARK: Syncing

extension BookingDetailsViewModel {
    func syncData() async {
        await syncBooking()
    }
}

private extension BookingDetailsViewModel {
    func syncBooking() async {
        guard booking.bookingID > 0 else {
            return
        }

        do {
            try await fetchRemoteBooking()
        } catch {
            DDLogError("⛔️ Error synchronizing Booking: \(error)")
        }
    }

    @MainActor
    func fetchRemoteBooking() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            let action = BookingAction.synchronizeBooking(
                siteID: booking.siteID,
                bookingID: booking.bookingID
            ) { result in
                switch result {
                case .success:
                    continuation.resume(returning: ())
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            stores.dispatch(action)
        }
    }
}

extension BookingDetailsViewModel {
    var cancellationAlertMessage: String {
        let productName = booking.orderInfo?.productInfo?.name ?? ""

        let customerName: String = {
            guard let address = booking.orderInfo?.customerInfo?.billingAddress else {
                return ""
            }
            return [address.firstName, address.lastName]
                .compactMap { $0 }
                .joined(separator: " ")
        }()

        let date = booking.startDate.formatted(
            date: .long,
            time: .shortened
        )

        return String(
            format: Localization.cancelBookingAlertMessage,
            customerName,
            productName,
            date
        )
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

        static let cancelBookingAlertMessage = NSLocalizedString(
            "BookingDetailsView.cancelation.alert.message",
            value: "%1$@ will no longer be able to attend “%2$@” on %3$@.",
            comment: "Message for the booking cancellation confirmation alert. %1$@ is customer name, %2$@ is product name, %3$@ is booking date."
        )
    }
}
