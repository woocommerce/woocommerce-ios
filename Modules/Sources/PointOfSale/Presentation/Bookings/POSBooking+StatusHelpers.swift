import struct Yosemite.POSBooking

extension POSBooking {
    var lifecycleStatus: POSBookingLifecycleStatus {
        POSBookingLifecycleStatus(bookingStatus: status)
    }

    var paymentStatus: POSBookingPaymentStatus {
        POSBookingPaymentStatus(booking: self)
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
