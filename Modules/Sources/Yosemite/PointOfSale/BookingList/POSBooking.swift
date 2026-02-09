import Foundation
import enum Networking.BookingStatus
import enum Networking.BookingAttendanceStatus
import enum Networking.BookingPaymentStatus

public struct POSBooking: Equatable, Hashable, Identifiable {
    public let id: Int64
    public let customerName: String
    public let serviceName: String
    public let startDate: Date
    public let endDate: Date
    public let formattedAmount: String
    public let bookingStatus: BookingStatus
    public let attendanceStatus: BookingAttendanceStatus
    public let paymentStatus: BookingPaymentStatus
    public let orderID: Int64?
    public let resourceName: String?

    public init(id: Int64,
                customerName: String,
                serviceName: String,
                startDate: Date,
                endDate: Date,
                formattedAmount: String,
                bookingStatus: BookingStatus,
                attendanceStatus: BookingAttendanceStatus,
                paymentStatus: BookingPaymentStatus,
                orderID: Int64?,
                resourceName: String?) {
        self.id = id
        self.customerName = customerName
        self.serviceName = serviceName
        self.startDate = startDate
        self.endDate = endDate
        self.formattedAmount = formattedAmount
        self.bookingStatus = bookingStatus
        self.attendanceStatus = attendanceStatus
        self.paymentStatus = paymentStatus
        self.orderID = orderID
        self.resourceName = resourceName
    }
}
