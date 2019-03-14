import Foundation

/// Represents a Shipment Tracking Provider Grouping Entity (from the WC Shipment Tracking extension).
///
public struct ShipmentTrackingProviderGroup {
    /// Tracking provider group name
    ///
    public let name: String

    /// Tracking providers belonging to the group
    ///
    public let providers: [ShipmentTrackingProvider]

    init(name: String, providers: [ShipmentTrackingProvider]) {
        self.name = name
        self.providers = providers
    }

    public init(name: String, dictionary: [String: String]?) {
        let providers = dictionary?.map({ ShipmentTrackingProvider(name: $0.key, url: $0.value) }) ?? []
        self.init(name: name, providers: providers)
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
