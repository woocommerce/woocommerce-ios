import Foundation
import CoreData

extension Booking {

    @NSManaged public var bookingID: Int64
    @NSManaged public var siteID: Int64
    @NSManaged public var parentID: Int64
    @NSManaged public var productID: Int64
    @NSManaged public var orderID: Int64
    @NSManaged public var resourceID: Int64
    @NSManaged public var allDay: Bool
    @NSManaged public var cost: String?
    @NSManaged public var customerID: Int64
    @NSManaged public var userID: Int64
    @NSManaged public var dateCreated: Date?
    @NSManaged public var dateModified: Date?
    @NSManaged public var endDate: Date?
    @NSManaged public var startDate: Date?
    @NSManaged public var googleCalendarEventID: String?
    @NSManaged public var orderItemID: Int64
    @NSManaged public var statusKey: String?
    @NSManaged public var attendanceStatusKey: String?
    @NSManaged public var localTimezone: String?
    @NSManaged public var currency: String?
    @NSManaged public var orderInfo: BookingOrderInfo?
    @NSManaged public var note: String?
}
