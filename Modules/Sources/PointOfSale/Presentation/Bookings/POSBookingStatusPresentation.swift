import SwiftUI
import enum Yosemite.BookingStatus
import enum Yosemite.BookingAttendanceStatus
import struct Yosemite.POSBooking

/// POS presentation-only interpretation of booking statuses.
///
/// The backend API uses a single `status` field that combines booking lifecycle and payment
/// semantics (e.g. `paid`, `unpaid`, `confirmed`, `cancelled`, `complete`).
/// For POS display, we interpret this into three independent dimensions:
///
/// 1. **Booking lifecycle**: Booked / Completed / Cancelled
///    - Only "Cancelled" is shown as a badge. Booked/Completed are automatic transitions.
/// 2. **Payment status**: Paid / Unpaid
///    - Derived from the API `status` field values.
/// 3. **Attendance status**: Unattended / Attended
///    - Comes from the API `attendance_status` field.
// TODO: WOOMOB-2143 - Revisit status matching once status-matching changes land.

// MARK: - Payment Status (derived from BookingStatus)

enum POSBookingPaymentStatus: Equatable {
    case paid
    case unpaid
    case refunded

    init(booking: POSBooking) {
        if booking.order.status == .refunded {
            self = .refunded
            return
        }

        switch booking.status {
        case .paid, .complete:
            self = .paid
        case .unpaid, .pendingConfirmation, .confirmed, .unknown:
            self = .unpaid
        case .cancelled:
            self = booking.order.datePaid == nil ? .unpaid : .paid
        }
    }

    var localizedTitle: String {
        switch self {
        case .paid:
            return Localization.paid
        case .unpaid:
            return Localization.unpaid
        case .refunded:
            return Localization.refunded
        }
    }

    var color: Color { textColor }

    var textColor: Color {
        switch self {
        case .paid:
            return .posOnDefault
        case .unpaid:
            return .posOnErrorLowest
        case .refunded:
            return .posOnErrorLowest
        }
    }

    var backgroundColor: Color {
        switch self {
        case .paid:
            return .posDefault
        case .unpaid:
            return .posErrorLowest
        case .refunded:
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
            return .posOnErrorLowest
        case .booked, .completed:
            return .clear
        }
    }

    var backgroundColor: Color {
        switch self {
        case .cancelled:
            return .posErrorLowest
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
