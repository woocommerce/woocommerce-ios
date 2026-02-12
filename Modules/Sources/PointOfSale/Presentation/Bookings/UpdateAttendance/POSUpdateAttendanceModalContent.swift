import SwiftUI
import struct Yosemite.POSBooking
import enum Yosemite.BookingAttendanceStatus

struct POSUpdateAttendanceModalContent: View {
    let state: UpdateAttendanceModalState
    let booking: POSBooking
    let targetStatus: POSBookingAttendanceDisplay
    @Binding var updateAttendanceModalState: UpdateAttendanceModalState?

    @Environment(POSBookingsModel.self) private var bookingsModel

    var body: some View {
        switch state {
        case .confirmation:
            POSUpdateAttendanceConfirmationView(
                targetStatus: targetStatus,
                serviceName: booking.serviceName,
                formattedDateTime: formattedDateTime,
                customerName: booking.customerName,
                isProcessing: false,
                onClose: { updateAttendanceModalState = nil },
                onConfirm: {
                    updateAttendanceModalState = .processing
                    Task { @MainActor in
                        await performUpdateAttendance()
                    }
                },
                onBack: { updateAttendanceModalState = nil }
            )
        case .processing:
            POSUpdateAttendanceConfirmationView(
                targetStatus: targetStatus,
                serviceName: booking.serviceName,
                formattedDateTime: formattedDateTime,
                customerName: booking.customerName,
                isProcessing: true,
                onClose: {},
                onConfirm: {},
                onBack: {}
            )
        case .success:
            POSUpdateAttendanceSuccessView(
                targetStatus: targetStatus,
                onDone: { updateAttendanceModalState = nil },
                onClose: { updateAttendanceModalState = nil }
            )
        case .error:
            POSRefundErrorView(
                title: Localization.errorTitle,
                subtitle: Localization.errorSubtitle,
                onRetry: {
                    updateAttendanceModalState = .processing
                    Task { @MainActor in
                        await performUpdateAttendance()
                    }
                },
                onCancel: { updateAttendanceModalState = nil },
                onClose: { updateAttendanceModalState = nil }
            )
        }
    }

    private var formattedDateTime: String {
        DateFormatter.dateTimeFormatter.string(from: booking.startDate)
    }

    private var targetAttendanceStatus: BookingAttendanceStatus {
        switch targetStatus {
        case .attended:
            return .attended
        case .unattended:
            return .unattended
        }
    }

    @MainActor
    private func performUpdateAttendance() async {
        do {
            try await bookingsModel.bookingsController.updateAttendanceStatus(
                bookingID: booking.id,
                status: targetAttendanceStatus
            )
            updateAttendanceModalState = .success
        } catch {
            updateAttendanceModalState = .error
        }
    }
}

// MARK: - Date Formatters

private extension DateFormatter {
    static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - Localization

private enum Localization {
    static let errorTitle = NSLocalizedString(
        "pos.updateAttendance.error.title",
        value: "Failed to update attendance",
        comment: "Title shown when updating attendance status from POS has failed."
    )

    static let errorSubtitle = NSLocalizedString(
        "pos.updateAttendance.error.subtitle",
        value: "Please try again.",
        comment: "Subtitle shown when updating attendance status from POS has failed."
    )
}
