import Foundation
import Yosemite

final class BookingDetailsViewModel: ObservableObject {
    private let stores: StoresManager

    private var booking: Booking

    // EntityListener: Update / Deletion Notifications.
    ///
    private lazy var entityListener: EntityListener<Booking> = {
        return EntityListener(storageManager: ServiceLocator.storageManager, readOnlyEntity: booking)
    }()

    let navigationTitle: String
    @Published private(set) var sections: [Section] = []

    init(booking: Booking, stores: StoresManager = ServiceLocator.stores) {
        self.booking = booking
        self.stores = stores

        navigationTitle = Self.navigationTitle(for: booking)
        setupSections(with: booking)
        configureEntityListener()
    }

    private func setupSections(with booking: Booking) {
        let headerContent = HeaderContent(booking)
        let headerSection = Section(
            content: .header(headerContent)
        )

        let appointmentDetailsSection = Section(
            header: .title(Localization.appointmentDetailsSectionHeaderTitle.uppercased()),
            content: .appointmentDetails(AppointmentDetailsContent(booking))
        )

        let customerSection: Section? = {
            guard let billingAddress = booking.orderInfo?.customerInfo?.billingAddress else { return nil }
            let customerContent = CustomerContent(billingAddress: billingAddress)
            return Section(
                header: .title(Localization.customerSectionHeaderTitle.uppercased()),
                content: .customer(customerContent)
            )
        }()

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
            customerSection,
            attendanceSection,
            paymentSection,
            bookingNotes
        ].compactMap { $0 }
    }
}

// MARK: Syncing

extension BookingDetailsViewModel {
    func syncData() async {
        await syncBooking()
    }
}

private extension BookingDetailsViewModel {
    func configureEntityListener() {
        entityListener.onUpsert = { [weak self] booking in
            guard let self else { return }
            self.booking = booking
            self.setupSections(with: booking)
        }
    }

    func syncBooking() async {
        do {
            try await retrieveBooking()
        } catch {
            DDLogError("⛔️ Error synchronizing Customer for Booking: \(error)")
        }
    }

    @MainActor
    func retrieveBooking() async throws {
        try await withCheckedThrowingContinuation { continuation in
            let action = BookingAction.synchronizeBooking(
                siteID: booking.siteID,
                bookingID: booking.bookingID
            ) { result in
                continuation.resume(with: result)
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
