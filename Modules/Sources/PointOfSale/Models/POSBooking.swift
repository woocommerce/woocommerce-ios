// POSBooking.swift
import Foundation

public enum POSBookingStatus: Equatable, Sendable {
    case unpaid
    case paid
    case cancelled
    case noLinkedOrder
}

public struct POSBooking: Equatable, Sendable, Identifiable {
    public let bookingID: Int64
    public let orderID: Int64?
    public let customerName: String
    public let serviceName: String
    public let startTime: Date
    public let amount: String
    public let isPaid: Bool
    public let isCancelled: Bool

    public var id: Int64 { bookingID }

    public var status: POSBookingStatus {
        if orderID == nil {
            return .noLinkedOrder
        }
        if isCancelled {
            return .cancelled
        }
        if isPaid {
            return .paid
        }
        return .unpaid
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
        amount: String,
        isPaid: Bool,
        isCancelled: Bool
    ) {
        self.bookingID = bookingID
        self.orderID = orderID
        self.customerName = customerName
        self.serviceName = serviceName
        self.startTime = startTime
        self.amount = amount
        self.isPaid = isPaid
        self.isCancelled = isCancelled
    }
}
