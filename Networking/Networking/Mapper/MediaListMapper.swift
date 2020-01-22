/// Mapper: Media List
///
struct MediaListMapper: Mapper {
    /// (Attempts) to convert a dictionary into an Account entity.
    ///
    func map(response: Data) throws -> [Media] {
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
