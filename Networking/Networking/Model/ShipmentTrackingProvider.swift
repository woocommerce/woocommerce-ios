import Foundation

/// Represents a Shipment Tracking Provider Entity (from the WC Shipment Tracking extension).
///
public struct ShipmentTrackingProvider {
    /// Tracking provider name
    ///
    public let name: String

    /// Site Identifier
    ///
    public let siteID: Int64

    /// Tracking provider url
    ///
    public let url: String

    /// Shipment Tracking Provider struct initializer
    ///
    public init(siteID: Int64, name: String, url: String) {
        self.siteID = siteID
        self.name = name
        self.url = url
    }
}


extension ShipmentTrackingProvider: Comparable {
    public static func ==(lhs: ShipmentTrackingProvider, rhs: ShipmentTrackingProvider) -> Bool {
        return lhs.name == rhs.name &&
            lhs.url == rhs.url &&
            lhs.siteID == rhs.siteID
    }
    public static func < (lhs: ShipmentTrackingProvider, rhs: ShipmentTrackingProvider) -> Bool {
        return lhs.name < rhs.name
    }
}


extension ShipmentTrackingProvider: CustomStringConvertible {
    public var description: String {
        return name
    }
}
