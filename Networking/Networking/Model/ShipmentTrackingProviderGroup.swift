import Foundation

/// Represents a Shipment Tracking Provider Grouping Entity (from the WC Shipment Tracking extension).
///
public struct ShipmentTrackingProviderGroup: Decodable {
    /// Tracking provider group name
    ///
    public let name: String

    /// Tracking providers belonging to the group
    ///
    public let providers: [ShipmentTrackingProvider]

    public init(name: String, providers: [ShipmentTrackingProvider]) {
        self.name = name
        self.providers = providers
    }

    /// The public initializer for ShipmentTrackingProvider.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.unkeyedContainer()
        self.init(name: "Name", providers: [])
    }
}

extension ShipmentTrackingProviderGroup: Comparable {
    public static func ==(lhs: ShipmentTrackingProviderGroup, rhs: ShipmentTrackingProviderGroup) -> Bool {
        return lhs.name == rhs.name
    }

    public static func <(lhs: ShipmentTrackingProviderGroup, rhs: ShipmentTrackingProviderGroup) -> Bool {
        return lhs.name < rhs.name
    }
}
