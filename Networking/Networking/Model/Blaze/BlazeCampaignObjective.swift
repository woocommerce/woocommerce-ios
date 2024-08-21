import Foundation
import Codegen

/// Objective for a Blaze ads campaign.
///
public struct BlazeCampaignObjective: Decodable, Equatable, Sendable, GeneratedFakeable, GeneratedCopiable {

    /// ID of the objective
    public let id: String

    /// Title of the objective
    public let title: String

    /// Description of the objective
    public let description: String

    /// Note for what the objective is suitable for
    public let suitableForDescription: String

    /// Locale of the objective name & descriptions
    public let locale: String

    public init(id: String, title: String, description: String, suitableForDescription: String, locale: String) {
        self.id = id
        self.title = title
        self.description = description
        self.suitableForDescription = suitableForDescription
        self.locale = locale
    }

    public init(from decoder: Decoder) throws {
        self.locale = decoder.userInfo[.locale] as? String ?? "en"
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.description = try container.decode(String.self, forKey: .description)
        self.suitableForDescription = try container.decode(String.self, forKey: .suitableForDescription)
    }

    private enum CodingKeys: CodingKey {
        case id
        case title
        case description
        case suitableForDescription
    }
}
