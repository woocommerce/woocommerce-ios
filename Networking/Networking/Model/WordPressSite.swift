import Foundation

/// Represents basic information for a WordPress site.
///
public struct WordPressSite: Decodable, Equatable {

    /// Site's Name.
    ///
    public let name: String

    /// Site's Description.
    ///
    public let description: String

    /// Site's URL.
    ///
    public let url: String

    /// Time zone identifier of the site (TZ database name).
    ///
    public let timezone: String

    /// Return the website UTC time offset, showing the difference in hours and minutes from UTC, from the westernmost (−12:00) to the easternmost (+14:00).
    ///
    public let gmtOffset: String

    public init(name: String, description: String, url: String, timezone: String, gmtOffset: String) {
        self.name = name
        self.description = description
        self.url = url
        self.timezone = timezone
        self.gmtOffset = gmtOffset
    }
}

public extension WordPressSite {
    /// Converts to `Site` with placeholder values for unknown fields.
    ///
    var asSite: Site {
        .init(siteID: Constants.placeholderSiteID, // Placeholder site ID
              name: name,
              description: description,
              url: url,
              adminURL: url + Constants.adminPath, // this would not work for sites with custom URLs
              loginURL: url + Constants.loginPath, // this would not work for sites with custom URLs
              frameNonce: "",
              plan: "",
              isJetpackThePluginInstalled: false,
              isJetpackConnected: false,
              isWooCommerceActive: true, // we expect to only call this after checking Woo is active
              isWordPressComStore: false,
              jetpackConnectionActivePlugins: [],
              timezone: timezone,
              gmtOffset: Double(gmtOffset) ?? 0)
    }
}

/// Defines all of the WordPressSite CodingKeys
///
private extension WordPressSite {
    enum CodingKeys: String, CodingKey {
        case name
        case description
        case url
        case timezone = "timezone_string"
        case gmtOffset = "gmt_offset"
    }

    enum Constants {
        static let placeholderSiteID: Int64 = -1
        static let adminPath = "/wp-admin"
        static let loginPath = "/wp-login.php"
    }
}
