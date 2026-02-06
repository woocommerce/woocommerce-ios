import Foundation
import enum Networking.BookingStatus
import enum Networking.BookingAttendanceStatus

public struct POSBooking: Equatable, Hashable, Identifiable {
    public let id: Int64
    public let customerName: String
    public let serviceName: String
    public let startDate: Date
    public let endDate: Date
    public let formattedAmount: String
    public let status: BookingStatus
    public let attendanceStatus: BookingAttendanceStatus
    public let orderID: Int64?
    public let resourceName: String?

    public init(id: Int64,
                customerName: String,
                serviceName: String,
                startDate: Date,
                endDate: Date,
                formattedAmount: String,
                status: BookingStatus,
                attendanceStatus: BookingAttendanceStatus,
                orderID: Int64?,
                resourceName: String?) {
        self.id = id
        self.customerName = customerName
        self.serviceName = serviceName
        self.startDate = startDate
        self.endDate = endDate
        self.formattedAmount = formattedAmount
        self.status = status
        self.attendanceStatus = attendanceStatus
        self.orderID = orderID
        self.resourceName = resourceName
    }
}
