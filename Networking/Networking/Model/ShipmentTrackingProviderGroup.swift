import Foundation

/// Represents a Shipment Tracking Provider Grouping Entity (from the WC Shipment Tracking extension).
///
public struct ShipmentTrackingProviderGroup {
    /// Tracking provider group name
    ///
    public let name: String

    /// Site Identifier
    ///
    public let siteID: Int

    /// Tracking providers belonging to the group
    ///
    public let providers: [ShipmentTrackingProvider]

    public init(name: String, siteID: Int, providers: [ShipmentTrackingProvider]) {
        self.name = name
        self.siteID = siteID
        self.providers = providers
    }

    public init(name: String, siteID: Int, dictionary: [String: String]?) {
        let providers = dictionary?.map({ ShipmentTrackingProvider(siteID: siteID, name: $0.key, url: $0.value) }) ?? []
        self.init(name: name, siteID: siteID, providers: providers)
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
