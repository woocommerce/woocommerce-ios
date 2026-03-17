import Foundation
import Yosemite
import protocol Storage.StorageManagerType
import protocol WooFoundation.Analytics
import SwiftUI

final class BookingDetailsViewModel: ObservableObject {
    private let stores: StoresManager
    private let storage: StorageManagerType

    private var bookingResource: BookingResource?
    private var isLoadingResource = false
    private var isLoadingLocation = false
    private var booking: Booking {
        didSet {
            updateDisplayProperties(from: booking)
        }
    }

    private let headerContent = HeaderContent()
    private let customerContent = CustomerContent()
    private let appointmentDetailsContent = AppointmentDetailsContent()
    private let paymentContent = PaymentContent()
    private let notesContent = NotesContent()
    private let analytics: Analytics

    // EntityListener: Update / Deletion Notifications.
    ///
    private lazy var entityListener: EntityListener<Booking> = {
        return EntityListener(storageManager: ServiceLocator.storageManager, readOnlyEntity: booking)
    }()

    @Published private(set) var navigationTitle = ""
    @Published private(set) var sections: [Section] = []
    @Published private(set) var isViewOrderAvailable = true
    @Published var notice: Notice?

    var bookingAttendanceStatus: BookingAttendanceStatus {
        booking.attendanceStatus
    }

    var shouldShowAttendanceButton: Bool {
        booking.bookingStatus != .cancelled
    }

    var attendanceButtonTitle: String {
        booking.attendanceStatus == .attended
            ? Localization.markAsUnattended
            : Localization.markAsAttended
    }

    var targetAttendanceStatus: BookingAttendanceStatus {
        booking.attendanceStatus == .attended ? .unattended : .attended
    }

    init(booking: Booking,
         stores: StoresManager = ServiceLocator.stores,
         storage: StorageManagerType = ServiceLocator.storageManager,
         analytics: Analytics = ServiceLocator.analytics) {
        self.booking = booking
        self.stores = stores
        self.storage = storage
        self.analytics = analytics
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
            header: .title(Localization.bookingNoteSectionHeaderTitle.uppercased()),
            footerText: Localization.bookingNoteSectionFooterText,
            content: .bookingNotes(notesContent)
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
        isViewOrderAvailable = booking.hasAssociatedOrder

        headerContent.update(with: booking)

        setupCustomerSectionVisibility()
        if let orderInfo = booking.orderInfo,
           let customerInfo = orderInfo.customerInfo,
           customerInfo.billingAddress.isEmpty == false {
            customerContent.update(with: customerInfo)
        }

        appointmentDetailsContent.update(with: booking,
                                        resource: bookingResource,
                                        bookingLocation: booking.location,
                                        isLoadingResource: isLoadingResource,
                                        isLoadingLocation: isLoadingLocation)

        paymentContent.update(with: booking)
        notesContent.update(with: booking)
    }

    func setupCustomerSectionVisibility() {
        if let billingAddress = booking.orderInfo?.customerInfo?.billingAddress, !billingAddress.isEmpty {
            insertCustomerSectionIfAbsent()
        } else {
            deleteCustomerSectionIfPresent()
        }
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
    @MainActor
    func syncData() async {
        isLoadingResource = bookingResource == nil && booking.resourceID > 0
        isLoadingLocation = booking.location == nil
        updateDisplayProperties(from: booking)

        async let resourceResult = fetchResource()
        async let bookingSync: Void = fetchBooking()

        if let resource = await resourceResult {
            self.bookingResource = resource
        }
        isLoadingResource = false
        _ = await bookingSync
        updateDisplayProperties(from: booking)

        await fetchBookingLocation()
        isLoadingLocation = false
        updateDisplayProperties(from: booking)
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
                self.analytics.track(event: .BookingsDetail.failedToUpdateBookingDetails(action: .updateAttendance, error: error))
                DDLogError("⛔️ Error updating booking attendance status: \(error)")
                displayErrorNotice(
                    messageFormat: Localization.bookingAttendanceStatusUpdateFailedMessage
                ) { [weak self] in
                    self?.updateAttendanceStatus(to: newStatus)
                }
            }
        }
        stores.dispatch(action)
        analytics.track(event: .BookingsDetail.attendanceStatusUpdate(status: newStatus))
    }

    func notesTapped() {
        analytics.track(event: .BookingsDetail.addNoteTap())
    }

    @MainActor
    func updateNote(to newNote: String) async -> MultilineCommitResult {
        await withCheckedContinuation { continuation in
            let action = BookingAction.updateBookingNote(
                siteID: booking.siteID,
                bookingID: booking.bookingID,
                note: newNote
            ) { [booking] error in
                if let error {
                    DDLogError("⛔️ Error updating booking note: \(error)")
                    let message = String.localizedStringWithFormat(
                        Localization.bookingNoteUpdateFailedMessage,
                        booking.bookingID
                    )

                    continuation.resume(returning: .failure(message: message))
                    return
                }

                continuation.resume(returning: .success)
            }

            stores.dispatch(action)
        }
    }

    private func displayErrorNotice(
        messageFormat: String,
        retry: @escaping () -> Void
    ) {
        let text = String.localizedStringWithFormat(
            messageFormat,
            booking.bookingID
        )

        notice = Notice(
            message: text,
            feedbackType: .error,
            actionTitle: Localization.retryActionTitle
        ) {
            retry()
        }
    }
}

/// Cancel booking
extension BookingDetailsViewModel {
    var isBookingCancellable: Bool {
        let ineligibleStatuses: [BookingStatus] = [.cancelled, .complete, .unknown]
        return !ineligibleStatuses.contains(booking.bookingStatus)
    }

    @MainActor
    func cancelBooking() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            stores.dispatch(BookingAction.cancelBooking(siteID: booking.siteID, bookingID: booking.bookingID) { [analytics] error in
                if let error {
                    continuation.resume(throwing: error)
                    analytics.track(event: .BookingsDetail.failedToUpdateBookingDetails(action: .cancelBooking, error: error))
                } else {
                    continuation.resume(returning: ())
                    analytics.track(event: .BookingsDetail.bookingCancelled())
                }
            })
        }
    }

    func displayBookingCancellationErrorNotice(onRetry: @escaping () -> Void) {
        let text = String.localizedStringWithFormat(
            Localization.bookingCancellationFailedMessage,
            booking.bookingID
        )
        self.notice = Notice(
            message: text,
            feedbackType: .error,
            actionTitle: Localization.retryActionTitle
        ) { onRetry() }
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
    func fetchBookingLocation() async {
        await withCheckedContinuation { continuation in
            let action = BookingAction.fetchBookingLocationResponse(
                siteID: booking.siteID,
                bookingID: booking.bookingID,
                productID: booking.productID
            ) { result in
                if case .failure(let error) = result {
                    DDLogError("⛔️ Error fetching booking location: \(error)")
                }
                continuation.resume()
            }
            stores.dispatch(action)
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
        let productName = booking.productName ?? ""
        let customerName = booking.customerName

        guard productName.isNotEmpty, customerName.isNotEmpty else {
            return Localization.cancelBookingAlertGenericMessage
        }

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

// MARK: Navigation

extension BookingDetailsViewModel {
    func navigateToOrderDetails() {
        analytics.track(event: .BookingsDetail.viewLinkedOrderTap())
        MainTabBarController.navigateToOrderDetails(with: booking.orderID, siteID: booking.siteID)
    }

    @MainActor
    func issueRefund() async {
        analytics.track(event: .BookingsDetail.refundTap())

        guard let order = storage.viewStorage.loadOrder(siteID: booking.siteID, orderID: booking.orderID)?.toReadOnly() else {
            DDLogError("⛔️ Order not found in storage for booking \(booking.bookingID)")
            assertionFailure("Order should be in storage after syncData()")
            return
        }

        let refunds = storage.viewStorage.loadRefunds(siteID: booking.siteID, orderID: booking.orderID).map { $0.toReadOnly() }
        presentRefundFlow(order: order, refunds: refunds)
    }
}

private extension BookingDetailsViewModel {
    func presentRefundFlow(order: Order, refunds: [Refund]) {
        let refundController = IssueRefundCoordinatingController(order: order, refunds: refunds)
        guard let presenter = UIApplication.wooKeyWindow?.topmostPresentedViewController else {
            return
        }
        refundController.onDismissCallback = { [weak self] in
            Task {
                await self?.syncData()
            }
        }
        presenter.present(refundController, animated: true)
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

        static let customerSectionHeaderTitle = NSLocalizedString(
            "BookingDetailsView.customer.headerTitle",
            value: "Customer",
            comment: "Header title for the 'Customer' section in the booking details screen."
        )

        static let markAsAttended = NSLocalizedString(
            "BookingDetailsView.attendance.markAsAttended",
            value: "Mark as attended",
            comment: "Button title to mark a booking's attendance as attended."
        )

        static let markAsUnattended = NSLocalizedString(
            "BookingDetailsView.attendance.markAsUnattended",
            value: "Mark as unattended",
            comment: "Button title to mark a booking's attendance as unattended."
        )

        static let paymentSectionHeaderTitle = NSLocalizedString(
            "BookingDetailsView.payment.headerTitle",
            value: "Payment",
            comment: "Header title for the 'Payment' section in the booking details screen."
        )

        static let bookingNoteSectionHeaderTitle = NSLocalizedString(
            "BookingDetailsView.bookingNote.headerTitle",
            value: "Booking note",
            comment: "Header title for the 'Booking note' section in the booking details screen."
        )

        static let bookingNoteSectionFooterText = NSLocalizedString(
            "BookingDetailsView.bookingNote.footerText",
            value: "This is a private note. It'll not be shared with the customer.",
            comment: "Footer text for the `Booking note` section in the booking details screen."
        )

        static let cancelBookingAlertMessage = NSLocalizedString(
            "BookingDetailsView.cancelation.alert.message",
            value: "%1$@ will no longer be able to attend “%2$@” on %3$@.",
            comment: "Message for the booking cancellation confirmation alert. %1$@ is customer name, %2$@ is product name, %3$@ is booking date."
        )

        static let cancelBookingAlertGenericMessage = NSLocalizedString(
            "BookingDetailsView.cancelation.alert.genericMessage",
            value: "Are you sure you want to cancel this booking?",
            comment: "Generic message for the booking cancellation confirmation alert."
        )

        static let bookingAttendanceStatusUpdateFailedMessage = NSLocalizedString(
            "BookingDetailsView.attendanceStatus.failureMessage.",
            value: "Unable to change attendance status of Booking #%1$d.",
            comment: "Content of error presented when updating the attendance status of a Booking fails. "
            + "It reads: Unable to change status of Booking #{Booking number}. "
            + "Parameters: %1$d - Booking number"
        )

        static let bookingNoteUpdateFailedMessage = NSLocalizedString(
            "BookingDetailsView.bookingNote.failureMessage.",
            value: "Unable to update note of Booking #%1$d.",
            comment: "Content of error presented when updating the not of a Booking fails. "
            + "It reads: Unable to update note of Booking #{Booking number}. "
            + "Parameters: %1$d - Booking number"
        )

        static let bookingCancellationFailedMessage = NSLocalizedString(
            "BookingDetailsView.cancellation.failureMessage",
            value: "Unable to cancel Booking #%1$d.",
            comment: "Content of error presented when cancelling a Booking fails. "
            + "It reads: Unable to cancel Booking #{Booking number}. "
            + "Parameters: %1$d - Booking number"
        )

        static let retryActionTitle = NSLocalizedString(
            "BookingDetailsView.retry.action",
            value: "Retry",
            comment: "Retry Action"
        )

    }
}
