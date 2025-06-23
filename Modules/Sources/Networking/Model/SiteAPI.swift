import Foundation
import Codegen

/// Encapsulates API Information for a given site
///
public struct SiteAPI: Decodable, Equatable, GeneratedFakeable {

    /// Site Identifier.
    ///
    public let siteID: Int64

    /// Available API namespaces
    ///
    public let namespaces: [String]

    /// Highest Woo API version installed on the site
    ///
    public var highestWooVersion: WooAPIVersion {
        if namespaces.contains(WooAPIVersion.mark3.rawValue) {
            return .mark3
        } else if namespaces.contains(WooAPIVersion.mark2.rawValue) {
            return .mark2
        } else if namespaces.contains(WooAPIVersion.mark1.rawValue) {
            return .mark1
        }

        return .none
    }

    /// Check if telemetry reporting namespace is available
    ///
    public var telemetryIsAvailable: Bool {
        return namespaces.contains(WooAPIVersion.wcTelemetry.rawValue)
    }

    /// Decodable Conformance.
    ///
    public init(from decoder: Decoder) throws {
        guard let siteID = decoder.userInfo[.siteID] as? Int64 else {
            throw SiteAPIError.missingSiteID
        }

        let siteAPIContainer = try decoder.container(keyedBy: SiteAPIKeys.self)
        let namespaces = siteAPIContainer.failsafeDecodeIfPresent([String].self, forKey: .namespaces) ?? []

        self.init(siteID: siteID, namespaces: namespaces)
    }

    /// Designated Initializer.
    ///
    public init(siteID: Int64, namespaces: [String]) {
        self.siteID = siteID
        self.namespaces = namespaces
    }
}


/// Defines all of the SiteAPI CodingKeys.
///
private extension SiteAPI {

    enum SiteAPIKeys: String, CodingKey {
        case namespaces = "namespaces"
    }
}


// MARK: - Decoding Errors
//
enum SiteAPIError: Error {
    case missingSiteID
}
