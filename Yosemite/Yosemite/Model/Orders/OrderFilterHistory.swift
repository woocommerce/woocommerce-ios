import Foundation

/// Models a pair of `siteID` and list of order settings
/// These entities will be serialized to a plist file using `AppSettingsStore`
///
public struct OrderFilterHistory: Codable, Equatable {
    /// SiteID: settings
    public let history: [Int64: [StoredOrderSettings.Setting]]

    public init(history: [Int64: [StoredOrderSettings.Setting]]) {
        self.history = history
    }
}
