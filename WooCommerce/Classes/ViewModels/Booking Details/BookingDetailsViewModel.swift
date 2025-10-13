import Foundation
import Yosemite
import SwiftUI // Added for withAnimation

final class BookingDetailsViewModel: ObservableObject {
    private let stores: StoresManager
    private lazy var resultsController = BookingDetailsResultsController(booking: booking)

    private let booking: Booking
    private let headerContent: HeaderContent
    private let customerContent = CustomerContent()
    private(set) var order: Order? {
        didSet {
            guard let order else {
                return
            }
            updateCustomerInfo(from: order)
        }
    }

    let navigationTitle: String
    @Published private(set) var sections: [Section] = []

    init(booking: Booking, stores: StoresManager = ServiceLocator.stores) {
        self.booking = booking
        self.stores = stores
        self.headerContent = HeaderContent(booking)
        navigationTitle = Self.navigationTitle(for: booking)
        setupSections()
        configureResultsController()
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
            self?.order = self?.resultsController.order
        }
        self.order = resultsController.order
    }

    func updateCustomerInfo(from order: Order) {
        guard let billingAddress = order.billingAddress else {
            return
        }

        customerContent.update(with: billingAddress)
        headerContent.update(with: billingAddress)
        insertCustomerSectionIfAbsent()
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
        await syncOrder()
    }
}

private extension BookingDetailsViewModel {
    func syncOrder() async {
        guard booking.orderID > 0 else {
            return
        }

        do {
            try await fetchRemoteOrder()
        } catch {
            DDLogError("⛔️ Error synchronizing Order for Booking: \(error)")
        }
    }

    @MainActor
    func fetchRemoteOrder() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            let action = OrderAction.retrieveOrder(
                siteID: booking.siteID,
                orderID: booking.orderID
            ) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                }
                continuation.resume(returning: ())
            }
            stores.dispatch(action)
        }
    }
}

extension BookingDetailsViewModel {
    var cancellationAlertMessage: String {
        // Temporary hardcoded
        //TODO: - replace with associated customer data
        let productName = "Women's Haircut"
        let customerName = "Margarita Nikolaevna"

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
