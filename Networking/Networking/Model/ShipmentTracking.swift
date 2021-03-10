import Foundation


/// Represents a Shipment Tracking Entity (from the WC Shipment Tracking extension).
///
public struct ShipmentTracking: Decodable, GeneratedFakeable {

    /// Site Identifier.
    ///
    public let siteID: Int64

    /// Order Identifier.
    ///
    public let orderID: Int64

    /// Unique identifier for shipment tracking
    ///
    public let trackingID: String

    /// Tracking number
    ///
    public let trackingNumber: String

    /// Tracking provider name
    ///
    public let trackingProvider: String?

    /// Tracking link
    ///
    public let trackingURL: String?

    /// Date when package was shipped
    ///
    public let dateShipped: Date?


    /// ShipmentTracking struct initializer.
    ///
    public init(siteID: Int64,
                orderID: Int64,
                trackingID: String,
                trackingNumber: String,
                trackingProvider: String?,
                trackingURL: String?,
                dateShipped: Date?) {
        self.siteID = siteID
        self.orderID = orderID
        self.trackingID = trackingID
        self.trackingNumber = trackingNumber
        self.trackingProvider = trackingProvider
        self.trackingURL = trackingURL
        self.dateShipped = dateShipped
    }

    /// The public initializer for ShipmentTracking.
    ///
    public init(from decoder: Decoder) throws {
        guard let siteID = decoder.userInfo[.siteID] as? Int64 else {
            throw ShipmentTrackingAPIError.missingSiteID
        }
        guard let orderID = decoder.userInfo[.orderID] as? Int64 else {
            throw ShipmentTrackingAPIError.missingOrderID
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        let trackingID = try container.decode(String.self, forKey: .trackingID)
        let trackingNumber = try container.decode(String.self, forKey: .trackingNumber)
        let trackingProvider = try container.decodeIfPresent(String.self, forKey: .trackingProvider)
        let trackingURL = try container.decodeIfPresent(String.self, forKey: .trackingURL)
        let dateShipped = try container.decodeIfPresent(Date.self, forKey: .dateShipped)

        self.init(siteID: siteID,
                  orderID: orderID,
                  trackingID: trackingID,
                  trackingNumber: trackingNumber,
                  trackingProvider: trackingProvider,
                  trackingURL: trackingURL,
                  dateShipped: dateShipped)  // initialize the struct
    }
}


/// Defines all of the ShipmentTracking's CodingKeys.
///
private extension ShipmentTracking {

    enum CodingKeys: String, CodingKey {
        case trackingID       = "tracking_id"
        case trackingNumber   = "tracking_number"
        case trackingProvider = "tracking_provider"
        case trackingURL      = "tracking_link"
        case dateShipped      = "date_shipped"
    }
}


// MARK: - Decoding Errors
//
enum ShipmentTrackingAPIError: Error {
    case missingSiteID
    case missingOrderID
}


// MARK: - Comparable Conformance
//
extension ShipmentTracking: Comparable {
    public static func == (lhs: ShipmentTracking, rhs: ShipmentTracking) -> Bool {
        return lhs.siteID == rhs.siteID &&
            lhs.orderID == rhs.orderID &&
            lhs.trackingID == rhs.trackingID &&
            lhs.trackingNumber == rhs.trackingNumber &&
            lhs.trackingProvider == rhs.trackingProvider &&
            lhs.trackingURL == rhs.trackingURL &&
            lhs.dateShipped == rhs.dateShipped
    }

    public static func < (lhs: ShipmentTracking, rhs: ShipmentTracking) -> Bool {
        return lhs.siteID < rhs.siteID ||
            (lhs.siteID == rhs.siteID && lhs.orderID < rhs.orderID) ||
            (lhs.siteID == rhs.siteID && lhs.orderID == rhs.orderID && lhs.trackingID < rhs.trackingID) ||
            (lhs.siteID == rhs.siteID && lhs.orderID == rhs.orderID && lhs.trackingID == rhs.trackingID && lhs.trackingNumber < rhs.trackingNumber)
    }

    public static func > (lhs: ShipmentTracking, rhs: ShipmentTracking) -> Bool {
        return lhs.siteID > rhs.siteID ||
            (lhs.siteID == rhs.siteID && lhs.orderID > rhs.orderID) ||
            (lhs.siteID == rhs.siteID && lhs.orderID == rhs.orderID && lhs.trackingID > rhs.trackingID) ||
            (lhs.siteID == rhs.siteID && lhs.orderID == rhs.orderID && lhs.trackingID == rhs.trackingID && lhs.trackingNumber > rhs.trackingNumber)
    }
}
