/// Mapper: Media
///
struct MediaMapper: Mapper {
    /// (Attempts) to convert data into a Media.
    ///
    func map(response: Data) async throws -> Media {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.iso8601)
        return try decoder.decode(Media.self, from: response)
    }
}

/// Mapper: Media List
///
struct MediaListMapper: Mapper {
    /// (Attempts) to convert data into a Media list.
    ///
    func map(response: Data) async throws -> [Media] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.iso8601)
        return try decoder.decode(MediaListEnvelope.self, from: response).mediaList
    }
}

private struct MediaListEnvelope: Decodable {
    let mediaList: [Media]

    private enum CodingKeys: String, CodingKey {
        case mediaList = "media"
    }
}
