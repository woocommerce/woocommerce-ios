import Foundation


/// Encapsulates API Information for a given site
///
public struct SiteAPI: Decodable {

    /// Site Identifier.
    ///
    public let siteID: Int

    /// Available API namespaces
    ///
    public let namespaces: [String]

    /// Decodable Conformance.
    ///
    public init(from decoder: Decoder) throws {
        guard let siteID = decoder.userInfo[.siteID] as? Int else {
            throw SiteAPIError.missingSiteID
        }

        let siteAPIContainer = try decoder.container(keyedBy: SiteAPIKeys.self)
        let namespaces = siteAPIContainer.failsafeDecodeIfPresent([String].self, forKey: .namespaces) ?? []

        self.init(siteID: siteID, namespaces: namespaces)
    }

    /// Designated Initializer.
    ///
    public init(siteID: Int, namespaces: [String]) {
        self.siteID = siteID
        self.namespaces = namespaces
    }
}


// MARK: - Comparable Conformance
//
extension SiteAPI: Comparable {
    public static func == (lhs: SiteAPI, rhs: SiteAPI) -> Bool {
        return lhs.siteID == rhs.siteID
    }

    public static func < (lhs: SiteAPI, rhs: SiteAPI) -> Bool {
        return lhs.siteID < rhs.siteID
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
