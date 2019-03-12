import Foundation

/// Represents a Shipment Tracking Provider Entity (from the WC Shipment Tracking extension).
///
public struct ShipmentTrackingProvider {
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

    public init?(dictionary: [String: String]?) {
        guard let dictionary = dictionary,
            let key = dictionary.keys.first,
            let value = dictionary[key] else {
            return nil
        }

        self.init(name: key, url: value)
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
