import struct Yosemite.POSBooking
import enum Yosemite.BookingPaymentStatus

extension POSBooking {
    var lifecycleStatus: POSBookingLifecycleStatus {
        POSBookingLifecycleStatus(bookingStatus: status)
    }

    var paymentStatus: BookingPaymentStatus {
        BookingPaymentStatus(booking: self)
    }

    var attendanceDisplay: POSBookingAttendanceDisplay {
        POSBookingAttendanceDisplay(attendanceStatus: attendanceStatus)
    }

    var isPaid: Bool {
        paymentStatus == .paid
    }

    var isCancellable: Bool {
        lifecycleStatus != .cancelled && lifecycleStatus != .completed
    }
}
