import Foundation
import Networking

/// Models a pair of `siteID` and list of product settings
/// These entities will be serialized to a plist file using `AppSettingsStore`
///
public struct ProductFilterHistory: Codable, Equatable {
    /// SiteID: settings
    public let history: [Int64: [StoredProductSettings.Setting]]

    public init(history: [Int64: [StoredProductSettings.Setting]]) {
        self.history = history
    }
}
