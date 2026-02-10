import Foundation
import enum Networking.BookingStatus
import enum Networking.BookingAttendanceStatus

public struct POSBooking: Equatable, Hashable, Identifiable {
    public let id: Int64
    public let customerName: String?
    public let serviceName: String
    public let startDate: Date
    public let endDate: Date
    public let formattedAmount: String
    public let status: BookingStatus
    public let attendanceStatus: BookingAttendanceStatus
    public let orderID: Int64?
    public let resourceName: String?
    public let resourceImageURL: String?
    public let customerEmail: String?
    public let customerPhone: String?
    public let billingAddress: String?
    public let customerNote: String?
    public let location: String?
    public let duration: String
    public let formattedSubtotal: String?
    public let formattedTax: String?
    public let order: POSOrder

    public init(id: Int64,
                customerName: String?,
                serviceName: String,
                startDate: Date,
                endDate: Date,
                formattedAmount: String,
                status: BookingStatus,
                attendanceStatus: BookingAttendanceStatus,
                orderID: Int64?,
                resourceName: String?,
                resourceImageURL: String? = nil,
                customerEmail: String? = nil,
                customerPhone: String? = nil,
                billingAddress: String? = nil,
                customerNote: String? = nil,
                location: String? = nil,
                duration: String = "",
                formattedSubtotal: String? = nil,
                formattedTax: String? = nil,
                order: POSOrder) {
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
        self.resourceImageURL = resourceImageURL
        self.customerEmail = customerEmail
        self.customerPhone = customerPhone
        self.billingAddress = billingAddress
        self.customerNote = customerNote
        self.location = location
        self.duration = duration
        self.formattedSubtotal = formattedSubtotal
        self.formattedTax = formattedTax
        self.order = order
    }
}
