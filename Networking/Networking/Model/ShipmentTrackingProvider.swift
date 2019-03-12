import Foundation

/// Represents a Shipment Tracking Provider Entity (from the WC Shipment Tracking extension).
///
public struct ShipmentTrackingProvider: Decodable {
    /// Tracking provider name
    ///
    public let name: String

    /// Tracking provider url
    ///
    public let url: String

    /// Shipment Tracking Provider struct initializer
    ///
    public init(name: String, url: String) {
        self.name = name
        self.url = url
    }

    /// The public initializer for ShipmentTrackingProvider.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.unkeyedContainer()
        self.init(name: "Name", url: "url")
    }
}

extension ShipmentTrackingProvider: Comparable {
    public static func ==(lhs: ShipmentTrackingProvider, rhs: ShipmentTrackingProvider) -> Bool {
        return lhs.name == rhs.name &&
            lhs.url == rhs.url
    }
    public static func < (lhs: ShipmentTrackingProvider, rhs: ShipmentTrackingProvider) -> Bool {
        return lhs.name < rhs.name
    }


}

