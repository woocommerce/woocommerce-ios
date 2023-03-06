import Foundation

struct AnnouncementListMapper: Mapper {

    /// (Attempts) to convert a dictionary into an AccountSettings entity.
    ///
    func map(response: Data) throws -> [Announcement] {
        let decoder = JSONDecoder()
        return try decoder.decode(AnnouncementsContainer.self, from: response).announcements
    }
}

public struct AnnouncementsContainer: Decodable {
    public let announcements: [Announcement]

    private enum CodingKeys: String, CodingKey {
        case announcements = "announcements"
    }

    public init(from decoder: Decoder) throws {
        let rootContainer = try decoder.container(keyedBy: CodingKeys.self)
        announcements = try rootContainer.decode([Announcement].self, forKey: .announcements)
    }
}
