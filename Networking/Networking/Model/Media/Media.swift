/// WordPress Site Media
///
public struct Media: GeneratedFakeable {
    public let mediaID: Int64
    public let date: Date    // gmt iso8601
    public let fileExtension: String
    public let mimeType: String
    public let src: String
    public let thumbnailURL: String?
    public let name: String?
    public let alt: String?
    public let height: Double?
    public let width: Double?

    /// Media initializer.
    ///
    public init(mediaID: Int64,
                date: Date,
                fileExtension: String,
                mimeType: String,
                src: String,
                thumbnailURL: String?,
                name: String?,
                alt: String?,
                height: Double?,
                width: Double?) {
        self.mediaID = mediaID
        self.date = date
        self.fileExtension = fileExtension
        self.mimeType = mimeType
        self.src = src
        self.thumbnailURL = thumbnailURL
        self.name = name
        self.alt = alt
        self.height = height
        self.width = width
    }
}

extension Media: Decodable {
    /// Decodable Initializer.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let mediaID = try container.decode(Int64.self, forKey: .mediaID)
        let date = try container.decodeIfPresent(Date.self, forKey: .date) ?? Date()
        let fileExtension = try container.decodeIfPresent(String.self, forKey: .fileExtension) ?? ""
        let mimeType = try container.decodeIfPresent(String.self, forKey: .mimeType) ?? ""
        let src = try container.decodeIfPresent(URL.self, forKey: .src)?.absoluteString ?? ""
        let name = try container.decode(String.self, forKey: .name)
        let alt = try container.decodeIfPresent(String.self, forKey: .alt)
        let height = try container.decodeIfPresent(Double.self, forKey: .height)
        let width = try container.decodeIfPresent(Double.self, forKey: .width)

        let thumbnailsByType = try container.decodeIfPresent(Dictionary<String, String>.self, forKey: .thumbnails)
        let thumbnailURL = thumbnailsByType?["thumbnail"]

        self.init(mediaID: mediaID,
                  date: date,
                  fileExtension: fileExtension,
                  mimeType: mimeType,
                  src: src,
                  thumbnailURL: thumbnailURL,
                  name: name,
                  alt: alt,
                  height: height,
                  width: width)
    }
}

private extension Media {
    enum CodingKeys: String, CodingKey {
        case mediaID  = "ID"
        case date
        case fileExtension = "extension"
        case mimeType = "mime_type"
        case src = "URL"
        case thumbnails
        case name = "title"
        case alt
        case height
        case width
    }
}
