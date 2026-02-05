// POSBooking.swift
import Foundation

/// Combined status for a booking (used for UI display)
/// Combines payment and attendance status for backwards compatibility
public enum POSBookingStatus: Equatable, Sendable {
    case unpaid
    case paid
    case cancelled
    case noLinkedOrder
}

/// Attendance status for a booking (booking status)
public enum POSBookingAttendanceStatus: Equatable, Sendable {
    case booked
    case checkedIn
    case cancelled
    case noShow
    case unknown
}

public struct POSBooking: Equatable, Hashable, Sendable, Identifiable {
    public let bookingID: Int64
    public let orderID: Int64?
    public let customerName: String
    public let serviceName: String
    public let startTime: Date
    public let endTime: Date
    public let amount: String
    public let isPaid: Bool
    public let isCancelled: Bool

    // Additional detail fields
    public let resourceName: String?
    public let customerEmail: String?
    public let customerPhone: String?
    public let subtotal: String?
    public let tax: String?
    public let attendanceStatus: POSBookingAttendanceStatus

    public var id: Int64 { bookingID }

    /// Combined status for display (considers both payment and attendance)
    public var status: POSBookingStatus {
        if orderID == nil {
            return .noLinkedOrder
        }
        if attendanceStatus == .cancelled || isCancelled {
            return .cancelled
        }
        if isPaid {
            return .paid
        }
        return .unpaid
    }

    /// Duration of the booking in minutes
    public var durationMinutes: Int {
        Int(endTime.timeIntervalSince(startTime) / 60)
    }

    public var canCollectPayment: Bool {
        status == .unpaid
    }

    public init(
        bookingID: Int64,
        orderID: Int64?,
        customerName: String,
        serviceName: String,
        startTime: Date,
        endTime: Date,
        amount: String,
        isPaid: Bool,
        isCancelled: Bool,
        resourceName: String? = nil,
        customerEmail: String? = nil,
        customerPhone: String? = nil,
        subtotal: String? = nil,
        tax: String? = nil,
        attendanceStatus: POSBookingAttendanceStatus = .booked
    ) {
        self.bookingID = bookingID
        self.orderID = orderID
        self.customerName = customerName
        self.serviceName = serviceName
        self.startTime = startTime
        self.endTime = endTime
        self.amount = amount
        self.isPaid = isPaid
        self.isCancelled = isCancelled
        self.resourceName = resourceName
        self.customerEmail = customerEmail
        self.customerPhone = customerPhone
        self.subtotal = subtotal
        self.tax = tax
        self.attendanceStatus = attendanceStatus
    }
}
