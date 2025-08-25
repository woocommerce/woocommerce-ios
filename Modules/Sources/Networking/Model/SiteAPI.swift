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

    /// Whether application password authentication is available
    ///
    public let applicationPasswordAvailable: Bool

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
        let authentication = try? siteAPIContainer.decode(Authentication.self, forKey: .authentication)
        let applicationPasswordAvailable = authentication?.applicationPasswords?.endpoints?.authorization != nil

        self.init(siteID: siteID, namespaces: namespaces, applicationPasswordAvailable: applicationPasswordAvailable)
    }

    /// Designated Initializer.
    ///
    public init(siteID: Int64, namespaces: [String], applicationPasswordAvailable: Bool) {
        self.siteID = siteID
        self.namespaces = namespaces
        self.applicationPasswordAvailable = applicationPasswordAvailable
    }
}


/// Defines all of the SiteAPI CodingKeys.
///
private extension SiteAPI {

    enum SiteAPIKeys: String, CodingKey {
        case namespaces
        case authentication
    }

    struct Authentication: Decodable {
        let applicationPasswords: ApplicationPasswords?
        enum CodingKeys: String, CodingKey {
            case applicationPasswords = "application-passwords"
        }
    }

    struct ApplicationPasswords: Decodable {
        let endpoints: Endpoints?
    }

    struct Endpoints: Decodable {
        let authorization: String?
    }
}


// MARK: - Decoding Errors
//
enum SiteAPIError: Error {
    case missingSiteID
}
