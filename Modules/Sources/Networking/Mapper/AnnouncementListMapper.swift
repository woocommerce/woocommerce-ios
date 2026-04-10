import Foundation

/// Mapper for `[Announcement]`
struct AnnouncementListMapper: Mapper {

    /// (Attempts) to convert a dictionary into a list of `Announcement`.
    ///
    func map(response: Data) throws -> [Announcement] {
        let decoder = JSONDecoder()
        return try decoder.decode(AnnouncementsContainer.self, from: response).announcements
    }
}

private struct AnnouncementsContainer: Decodable {
    public let announcements: [Announcement]

    private enum CodingKeys: String, CodingKey {
        case announcements = "announcements"
    }

    fileprivate init(from decoder: Decoder) throws {
        let rootContainer = try decoder.container(keyedBy: CodingKeys.self)
        announcements = try rootContainer.decode([Announcement].self, forKey: .announcements)
    }
}
