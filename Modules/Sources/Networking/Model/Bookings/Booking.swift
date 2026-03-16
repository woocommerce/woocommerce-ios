import Codegen
import Foundation

/// Represents a Booking Entity.
///
public struct Booking: Codable, GeneratedCopiable, Hashable, GeneratedFakeable {
    public let siteID: Int64
    public let bookingID: Int64
    public let allDay: Bool
    public let cost: String
    public let customerID: Int64
    public let dateCreated: Date?
    public let dateModified: Date?
    public let endDate: Date
    public let googleCalendarEventID: String?
    public let orderID: Int64
    public let orderItemID: Int64
    public let parentID: Int64
    public let productID: Int64
    public let resourceID: Int64
    public let startDate: Date
    public let statusKey: String
    public let attendanceStatusKey: String
    public let localTimezone: String
    public let currency: String
    public let orderInfo: BookingOrderInfo?
    public let note: String
    public let location: String?

    public var bookingStatus: BookingStatus {
        return BookingStatus(rawValue: statusKey) ?? .unknown
    }

    public var attendanceStatus: BookingAttendanceStatus {
        return BookingAttendanceStatus(rawValue: attendanceStatusKey) ?? .unknown
    }

    /// Booking struct initializer.
    ///
    public init(siteID: Int64,
                bookingID: Int64,
                allDay: Bool,
                cost: String,
                customerID: Int64,
                dateCreated: Date?,
                dateModified: Date?,
                endDate: Date,
                googleCalendarEventID: String?,
                orderID: Int64,
                orderItemID: Int64,
                parentID: Int64,
                productID: Int64,
                resourceID: Int64,
                startDate: Date,
                statusKey: String,
                attendanceStatusKey: String,
                localTimezone: String,
                currency: String,
                orderInfo: BookingOrderInfo?,
                note: String,
                location: String? = nil) {
        self.siteID = siteID
        self.bookingID = bookingID
        self.allDay = allDay
        self.cost = cost
        self.customerID = customerID
        self.dateCreated = dateCreated
        self.dateModified = dateModified
        self.endDate = endDate
        self.googleCalendarEventID = googleCalendarEventID
        self.orderID = orderID
        self.orderItemID = orderItemID
        self.parentID = parentID
        self.productID = productID
        self.resourceID = resourceID
        self.startDate = startDate
        self.statusKey = statusKey
        self.attendanceStatusKey = attendanceStatusKey
        self.localTimezone = localTimezone
        self.currency = currency
        self.orderInfo = orderInfo
        self.note = note
        self.location = location
    }

    /// The public initializer for Booking.
    ///
    public init(from decoder: Decoder) throws {
        guard let siteID = decoder.userInfo[.siteID] as? Int64 else {
            throw BookingDecodingError.missingSiteID
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)

        let bookingID = try container.decode(Int64.self, forKey: .bookingID)
        let allDay = try container.decode(Bool.self, forKey: .allDay)

        // Cost may come as string or number
        let cost = container.failsafeDecodeIfPresent(targetType: String.self,
                                                     forKey: .cost,
                                                     alternativeTypes: [.decimal(transform: { NSDecimalNumber(decimal: $0).stringValue })]) ?? ""

        let customerID = try container.decode(Int64.self, forKey: .customerID)

        let dateCreated: Date?
        if let dateCreatedValue = try container.decodeIfPresent(
            Double.self,
            forKey: .dateCreated
        ) {
            dateCreated = Date(timeIntervalSince1970: dateCreatedValue)
        } else {
            dateCreated = nil
        }

        let dateModified: Date?
        if let dateModifiedValue = try container.decodeIfPresent(
            Double.self,
            forKey: .dateModified
        ) {
            dateModified = Date(timeIntervalSince1970: dateModifiedValue)
        } else {
            dateModified = nil
        }

        let endDate = Date(timeIntervalSince1970: try container.decode(Double.self, forKey: .endDate))
        let googleCalendarEventID = try container.decodeIfPresent(String.self, forKey: .googleCalendarEventID)
        let orderID = try container.decode(Int64.self, forKey: .orderID)
        let orderItemID = try container.decode(Int64.self, forKey: .orderItemID)
        let parentID = try container.decode(Int64.self, forKey: .parentID)
        let productID = try container.decode(Int64.self, forKey: .productID)
        let resourceID = try container.decode(Int64.self, forKey: .resourceID)
        let startDate = Date(timeIntervalSince1970: try container.decode(Double.self, forKey: .startDate))
        let statusKey = try container.decode(String.self, forKey: .statusKey)
        let attendanceStatusKey = container.failsafeDecodeIfPresent(String.self, forKey: .attendanceStatusKey) ?? ""
        let localTimezone = try container.decode(String.self, forKey: .localTimezone)
        let currency = try container.decode(String.self, forKey: .currency)
        let orderInfo: BookingOrderInfo? = nil // to be prefilled when synced
        let note = try container.decode(String.self, forKey: .note)
        let location: String? = nil // fetched separately from the product endpoint

        self.init(siteID: siteID,
                  bookingID: bookingID,
                  allDay: allDay,
                  cost: cost,
                  customerID: customerID,
                  dateCreated: dateCreated,
                  dateModified: dateModified,
                  endDate: endDate,
                  googleCalendarEventID: googleCalendarEventID,
                  orderID: orderID,
                  orderItemID: orderItemID,
                  parentID: parentID,
                  productID: productID,
                  resourceID: resourceID,
                  startDate: startDate,
                  statusKey: statusKey,
                  attendanceStatusKey: attendanceStatusKey,
                  localTimezone: localTimezone,
                  currency: currency,
                  orderInfo: orderInfo,
                  note: note,
                  location: location)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(bookingID, forKey: .bookingID)
        try container.encode(allDay, forKey: .allDay)
        try container.encode(cost, forKey: .cost)
        try container.encode(customerID, forKey: .customerID)
        try container.encode(dateCreated, forKey: .dateCreated)
        try container.encode(dateModified, forKey: .dateModified)
        try container.encode(endDate, forKey: .endDate)
        try container.encode(googleCalendarEventID, forKey: .googleCalendarEventID)
        try container.encode(orderID, forKey: .orderID)
        try container.encode(orderItemID, forKey: .orderItemID)
        try container.encode(parentID, forKey: .parentID)
        try container.encode(productID, forKey: .productID)
        try container.encode(resourceID, forKey: .resourceID)
        try container.encode(startDate, forKey: .startDate)
        try container.encode(statusKey, forKey: .statusKey)
        try container.encode(attendanceStatusKey, forKey: .attendanceStatusKey)
        try container.encode(localTimezone, forKey: .localTimezone)
    }
}

extension Booking: Identifiable {
    public var id: Int64 { bookingID }
}

/// Defines all of the Booking CodingKeys
///
private extension Booking {

    enum CodingKeys: String, CodingKey {
        case bookingID = "id"
        case allDay = "all_day"
        case cost
        case customerID = "customer_id"
        case dateCreated = "date_created"
        case dateModified = "date_modified"
        case endDate = "end"
        case googleCalendarEventID = "google_calendar_event_id"
        case orderID = "order_id"
        case orderItemID = "order_item_id"
        case parentID = "parent_id"
        case personCounts = "person_counts"
        case productID = "product_id"
        case resourceID = "resource_id"
        case startDate = "start"
        case statusKey = "status"
        case attendanceStatusKey = "attendance_status"
        case localTimezone = "local_timezone"
        case currency
        case note
    }
}

// MARK: - Decoding Errors
//
enum BookingDecodingError: Error {
    case missingSiteID
}

// MARK: - Supporting Types
//

/// Represents a Booking Status.
public enum BookingStatus: String, CaseIterable, Codable {
    case complete
    case paid
    case unpaid
    case cancelled
    case pendingConfirmation = "pending-confirmation"
    case confirmed
    case unknown
}

public enum BookingAttendanceStatus: String, CaseIterable, Codable {
    case attended
    case unattended
    case unknown
}
