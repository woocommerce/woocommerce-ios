import Foundation
import Codegen

/// Details of a WordPress web page.
///
public struct WordPressPage: Decodable, Equatable, Identifiable, GeneratedCopiable, GeneratedFakeable {
    /// ID of the page in the site
    public let id: Int64

    /// Title of the page
    public let title: String

    /// Link of the page
    public let link: String

    public init(id: Int64, title: String, link: String) {
        self.id = id
        self.title = title
        self.link = link
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int64.self, forKey: .id)
        let titleDictionary = try container.decode([String: String].self, forKey: .title)
        title = titleDictionary["rendered"] ?? ""
        link = try container.decode(String.self, forKey: .link)
    }
}

private extension WordPressPage {
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case link
    }
}
