import SwiftUI
import enum Yosemite.BookingStatus
import enum Yosemite.BookingAttendanceStatus
import enum Yosemite.BookingPaymentStatus
import struct Yosemite.POSBooking

/// POS presentation-only interpretation of booking statuses.
///
/// The backend API uses a single `status` field that combines booking lifecycle and payment
/// semantics (e.g. `paid`, `unpaid`, `confirmed`, `cancelled`, `complete`).
/// For POS display, we interpret this into three independent dimensions:
///
/// 1. **Booking lifecycle**: Booked / Completed / Cancelled
///    - Only "Cancelled" is shown as a badge. Booked/Completed are automatic transitions.
/// 2. **Payment status**: Paid / Unpaid / Refunded / Failed
///    - Resolved from order data using the shared `BookingPaymentStatus` resolver.
/// 3. **Attendance status**: Unattended / Attended
///    - Comes from the API `attendance_status` field.

// MARK: - Payment Status (POS presentation for shared BookingPaymentStatus)

extension BookingPaymentStatus {
    /// Creates a payment status from a POS booking's order data.
    ///
    /// `refundTotal`/`total` are not available on `POSOrder` (amounts are pre-formatted),
    /// so partial-refund detection relies on the `orderStatus == .refunded` fallback.
    /// POS collapses `.partiallyRefunded` → "Refunded" in `localizedTitle` anyway.
    init(booking: POSBooking) {
        self.init(orderStatusKey: booking.order.status.rawValue,
                  datePaid: booking.order.datePaid)
    }

    var localizedTitle: String {
        switch self {
        case .paid:
            return Localization.paid
        case .unpaid:
            return Localization.unpaid
        case .refunded, .partiallyRefunded:
            return Localization.refunded
        case .failed:
            return Localization.failed
        }
    }

    var color: Color { textColor }

    var textColor: Color {
        switch self {
        case .paid:
            return .posOnDefault
        case .unpaid, .refunded, .partiallyRefunded, .failed:
            return .posOnErrorLowest
        }
    }

    var backgroundColor: Color {
        switch self {
        case .paid:
            return .posDefault
        case .unpaid, .refunded, .partiallyRefunded, .failed:
            return .posErrorLowest
        }
    }
}

// MARK: - Attendance Display (derived from BookingAttendanceStatus)

enum POSBookingAttendanceDisplay: Equatable {
    case attended
    case unattended

    init(attendanceStatus: BookingAttendanceStatus) {
        switch attendanceStatus {
        case .attended:
            self = .attended
        case .unattended, .unknown:
            self = .unattended
        }
    }

    var localizedTitle: String {
        switch self {
        case .attended:
            return Localization.attended
        case .unattended:
            return Localization.unattended
        }
    }

    var textColor: Color {
        .posOnDefault
    }

    var backgroundColor: Color {
        .posDefault
    }
}

// MARK: - Booking Lifecycle (derived from BookingStatus)

enum POSBookingLifecycleStatus: Equatable {
    case booked
    case completed
    case cancelled

    init(bookingStatus: BookingStatus) {
        switch bookingStatus {
        case .cancelled:
            self = .cancelled
        case .complete:
            self = .completed
        case .paid, .unpaid, .confirmed, .pendingConfirmation, .unknown:
            self = .booked
        }
    }

    /// Whether the status should be displayed as a badge.
    /// Only `cancelled` is shown — `booked` and `completed` are automatic transitions.
    var shouldShowBadge: Bool {
        self == .cancelled
    }

    var localizedTitle: String {
        switch self {
        case .booked:
            return Localization.booked
        case .completed:
            return Localization.completed
        case .cancelled:
            return Localization.cancelled
        }
    }

    var badgeColor: Color { textColor }

    var textColor: Color {
        switch self {
        case .cancelled:
            return .posOnInfoLowest
        case .booked, .completed:
            return .clear
        }
    }

    var backgroundColor: Color {
        switch self {
        case .cancelled:
            return .posInfoLowest
        case .booked, .completed:
            return .clear
        }
    }
}

// MARK: - Localization

private enum Localization {
    static let paid = NSLocalizedString(
        "pos.bookingPaymentStatus.paid",
        value: "Paid",
        comment: "POS booking payment status label when the booking is paid."
    )

    static let unpaid = NSLocalizedString(
        "pos.bookingPaymentStatus.unpaid",
        value: "Unpaid",
        comment: "POS booking payment status label when the booking is unpaid."
    )

    static let refunded = NSLocalizedString(
        "pos.bookingPaymentStatus.refunded",
        value: "Refunded",
        comment: "POS booking payment status label when the booking order has been refunded."
    )

    static let failed = NSLocalizedString(
        "pos.bookingPaymentStatus.failed",
        value: "Failed",
        comment: "POS booking payment status label when the booking order payment failed."
    )

    static let attended = NSLocalizedString(
        "pos.bookingAttendanceDisplay.attended",
        value: "Attended",
        comment: "POS booking attendance status label when the customer attended."
    )

    static let unattended = NSLocalizedString(
        "pos.bookingAttendanceDisplay.unattended",
        value: "Unattended",
        comment: "POS booking attendance status label when the customer has not attended."
    )

    static let booked = NSLocalizedString(
        "pos.bookingLifecycleStatus.booked",
        value: "Booked",
        comment: "POS booking lifecycle status label for active bookings."
    )

    static let completed = NSLocalizedString(
        "pos.bookingLifecycleStatus.completed",
        value: "Completed",
        comment: "POS booking lifecycle status label for completed bookings."
    )

    static let cancelled = NSLocalizedString(
        "pos.bookingLifecycleStatus.cancelled",
        value: "Cancelled",
        comment: "POS booking lifecycle status label for cancelled bookings."
    )
}
