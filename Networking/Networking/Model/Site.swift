import Foundation


/// Represents a WordPress.com Site.
///
public struct Site: Decodable {

    /// WordPress.com Site Identifier.
    ///
    public let siteID: Int

    /// Site's Name.
    ///
    public let name: String

    /// Site's Description.
    ///
    public let description: String

    /// Site's URL.
    ///
    public let url: String

    /// Indicates if this site hosts a WordPress Store.
    ///
    public let isWordPressStore: Bool


    /// Decodable Conformance.
    ///
    public init(from decoder: Decoder) throws {
        let siteContainer = try decoder.container(keyedBy: SiteKeys.self)

        siteID = try siteContainer.decode(Int.self, forKey: .siteID)
        name = try siteContainer.decode(String.self, forKey: .name)
        description = try siteContainer.decode(String.self, forKey: .description)
        url = try siteContainer.decode(String.self, forKey: .url)

        let optionsContainer = try siteContainer.nestedContainer(keyedBy: OptionKeys.self, forKey: .options)
        isWordPressStore = try optionsContainer.decode(Bool.self, forKey: .isWordPressStore)
    }

    /// Designated Initializer.
    ///
    public init(siteID: Int, name: String, description: String, url: String, isWordPressStore: Bool) {
        self.siteID = siteID
        self.name = name
        self.description = description
        self.url = url
        self.isWordPressStore = isWordPressStore
    }
}


/// Defines all of the Site CodingKeys.
///
private extension Site {

    enum SiteKeys: String, CodingKey {
        case siteID         = "ID"
        case name           = "name"
        case description    = "description"
        case url            = "URL"
        case options        = "options"
    }

    enum OptionKeys: String, CodingKey {
        case isWordPressStore = "is_wpcom_store"
    }
}
