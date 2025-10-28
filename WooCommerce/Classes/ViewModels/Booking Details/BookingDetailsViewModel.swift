import Foundation
import Yosemite
import protocol Storage.StorageManagerType
import SwiftUI

final class BookingDetailsViewModel: ObservableObject {
    private let stores: StoresManager

    private var bookingResource: BookingResource?
    private var booking: Booking {
        didSet {
            updateDisplayProperties(from: booking)
        }
    }

    private let headerContent = HeaderContent()
    private let customerContent = CustomerContent()
    private let appointmentDetailsContent = AppointmentDetailsContent()
    private let attendanceContent = AttendanceContent()
    private let paymentContent = PaymentContent()

    // EntityListener: Update / Deletion Notifications.
    ///
    private lazy var entityListener: EntityListener<Booking> = {
        return EntityListener(storageManager: ServiceLocator.storageManager, readOnlyEntity: booking)
    }()

    @Published private(set) var navigationTitle = ""
    @Published private(set) var sections: [Section] = []
    @Published var notice: Notice?

    var bookingAttendanceStatus: BookingAttendanceStatus {
        booking.attendanceStatus
    }

    init(booking: Booking,
         stores: StoresManager = ServiceLocator.stores,
         storage: StorageManagerType = ServiceLocator.storageManager) {
        self.booking = booking
        self.stores = stores
        self.bookingResource = storage.viewStorage.loadBookingResource(
            siteID: booking.siteID,
            resourceID: booking.resourceID
        )?.toReadOnly()

        setupSections()
        configureEntityListener()

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
            content: .appointmentDetails(appointmentDetailsContent)
        )

        let paymentSection = Section(
            header: .title(Localization.paymentSectionHeaderTitle.uppercased()),
            content: .payment(paymentContent)
        )

        let bookingNotes = Section(
            header: .title(Localization.bookingNotesSectionHeaderTitle.uppercased()),
            content: .bookingNotes
        )

        sections = [
            headerSection,
            appointmentDetailsSection,
            paymentSection,
            bookingNotes
        ]
    }

    func updateDisplayProperties(from booking: Booking) {
        navigationTitle = Self.navigationTitle(for: booking)

        headerContent.update(with: booking)

        setupCustomerSectionVisibility()
        if let billingAddress = booking.orderInfo?.customerInfo?.billingAddress, !billingAddress.isEmpty {
            customerContent.update(with: billingAddress)
        }

        appointmentDetailsContent.update(with: booking, resource: bookingResource)

        setupAttendanceSectionVisibility()
        attendanceContent.update(with: booking)

        paymentContent.update(with: booking)
    }

    func setupCustomerSectionVisibility() {
        if let billingAddress = booking.orderInfo?.customerInfo?.billingAddress, !billingAddress.isEmpty {
            insertCustomerSectionIfAbsent()
        } else {
            deleteCustomerSectionIfPresent()
        }
    }

    func setupAttendanceSectionVisibility() {
        if booking.attendanceStatus == .cancelled || booking.bookingStatus == .cancelled {
            deleteAttendanceSectionIfPresent()
        } else {
            insertAttendanceSectionIfAbsent()
        }
    }

    func insertAttendanceSectionIfAbsent() {
        guard let insertAfterIndex = sections.firstIndex(where: {
            if case .customer = $0.content {
                return true
            }
            return false
        }) ?? sections.firstIndex(where: {
            if case .appointmentDetails = $0.content {
                return true
            }
            return false
        }) else {
            return
        }

        insertSectionIfAbsent(
            section: Section(
                header: .title(Localization.attendanceSectionHeaderTitle.uppercased()),
                footerText: Localization.attendanceSectionFooterText,
                content: .attendance(attendanceContent)
            ),
            at: insertAfterIndex + 1
        )
    }

    func insertCustomerSectionIfAbsent() {
        guard let insertAfterIndex = sections.firstIndex(where: {
            if case .appointmentDetails = $0.content {
                return true
            }
            return false
        }) else {
            return
        }

        insertSectionIfAbsent(
            section: Section(
                header: .title(Localization.customerSectionHeaderTitle.uppercased()),
                content: .customer(customerContent)
            ),
            at: insertAfterIndex + 1
        )
    }

    func insertSectionIfAbsent(section: Section, at index: Int) {
        let sectionExists = sections.contains {
            if section.content.id == $0.content.id {
                return true
            }

            return false
        }

        guard !sectionExists else {
            return
        }

        withAnimation {
            sections.insert(section, at: index)
        }
    }

    func deleteAttendanceSectionIfPresent() {
        guard let attendanceSectionIndex = sections.firstIndex(where: {
            if case .attendance = $0.content {
                return true
            }
            return false
        }) else {
            return
        }

        withAnimation {
            _ = sections.remove(at: attendanceSectionIndex)
        }
    }

    func deleteCustomerSectionIfPresent() {
        guard let customerSectionIndex = sections.firstIndex(where: {
            if case .customer = $0.content {
                return true
            }
            return false
        }) else {
            return
        }

        withAnimation {
            _ = sections.remove(at: customerSectionIndex)
        }
    }

    func configureEntityListener() {
        entityListener.onUpsert = { [weak self] booking in
            guard let self else { return }
            self.booking = booking
        }
    }
}

// MARK: Syncing

extension BookingDetailsViewModel {
    func syncData() async {
        if let resource = await fetchResource() {
            self.bookingResource = resource // only update resource if fetching succeeds
        }
        await fetchBooking()
    }
}

// MARK: Attendance status

extension BookingDetailsViewModel {
    func updateAttendanceStatus(to newStatus: BookingAttendanceStatus) {
        let action = BookingAction.updateBookingAttendanceStatus(
            siteID: booking.siteID,
            bookingID: booking.bookingID,
            status: newStatus
        ) { [weak self] error in
            if let error, let self {
                DDLogError("⛔️ Error updating booking attendance status: \(error)")
                displayAttendanceStatusUpdatedErrorNotice(status: newStatus)
            }
        }
        stores.dispatch(action)
    }

    private func displayAttendanceStatusUpdatedErrorNotice(status: BookingAttendanceStatus) {
        let text = String.localizedStringWithFormat(
            Localization.bookingAttendanceStatusUpdateFailedMessage,
            booking.bookingID
        )
        self.notice = Notice(
            message: text,
            feedbackType: .error,
            actionTitle: Localization.retryActionTitle
        ) { [weak self] in
            guard let self else {
                return
            }

            updateAttendanceStatus(to: status)
        }
    }
}

private extension BookingDetailsViewModel {
    @MainActor
    func fetchResource() async -> BookingResource? {
        do {
            return try await withCheckedThrowingContinuation { continuation in
                stores.dispatch(BookingAction.fetchResource(siteID: booking.siteID, resourceID: booking.resourceID) { result in
                    switch result {
                    case .success(let resource):
                        continuation.resume(returning: resource)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                })
            }
        } catch {
            DDLogError("⛔️ Error fetching resource for Booking: \(error)")
            return nil
        }
    }

    @MainActor
    func fetchBooking() async {
        do {
            try await withCheckedThrowingContinuation { continuation in
                let action = BookingAction.synchronizeBooking(
                    siteID: booking.siteID,
                    bookingID: booking.bookingID
                ) { result in
                    continuation.resume(with: result)
                }
                stores.dispatch(action)
            }
        } catch {
            DDLogError("⛔️ Error synchronizing Booking: \(error)")
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

        static let bookingAttendanceStatusUpdateFailedMessage = NSLocalizedString(
            "BookingDetailsView.attendanceStatus.updateFailed.message",
            value: "Unable to change attendance status of Booking #%1$d",
            comment: "Content of error presented when updating the attendance status of a Booking fails. "
            + "It reads: Unable to change status of Booking #{Booking number}. "
            + "Parameters: %1$d - Booking number"
        )

        static let retryActionTitle = NSLocalizedString(
            "BookingDetailsView.retry.action",
            value: "Retry",
            comment: "Retry Action"
        )
    }
}
