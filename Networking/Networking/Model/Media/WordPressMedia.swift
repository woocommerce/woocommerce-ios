import Codegen

/// Media from WordPress Site API
public struct WordPressMedia: Equatable {
    public let mediaID: Int64
    public let date: Date
    public let slug: String
    public let mimeType: String
    public let src: String
    public let alt: String?
    public let details: MediaDetails?
    public let title: MediaTitle?

    /// Media initializer.
    public init(mediaID: Int64,
                date: Date,
                slug: String,
                mimeType: String,
                src: String,
                alt: String?,
                details: MediaDetails?,
                title: MediaTitle?) {
        self.mediaID = mediaID
        self.date = date
        self.slug = slug
        self.mimeType = mimeType
        self.src = src
        self.alt = alt
        self.details = details
        self.title = title
    }
}

extension WordPressMedia: Decodable {
    /// Decodable Initializer.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let mediaID = try container.decode(Int64.self, forKey: .mediaID)
        let date = try container.decodeIfPresent(Date.self, forKey: .date) ?? Date()
        let slug = try container.decodeIfPresent(String.self, forKey: .slug) ?? ""
        let mimeType = try container.decodeIfPresent(String.self, forKey: .mimeType) ?? ""
        let src = try container.decodeIfPresent(String.self, forKey: .src) ?? ""
        let alt = try container.decodeIfPresent(String.self, forKey: .alt)
        let details = try container.decodeIfPresent(MediaDetails.self, forKey: .details)
        let title = try container.decodeIfPresent(MediaTitle.self, forKey: .title)

        self.init(mediaID: mediaID,
                  date: date,
                  slug: slug,
                  mimeType: mimeType,
                  src: src,
                  alt: alt,
                  details: details,
                  title: title)
    }
}

public extension WordPressMedia {
    /// Details about a WordPress site media.
    struct MediaDetails: Decodable, Equatable {
        public let width: Double
        public let height: Double
        public let fileName: String
        public let sizes: [String: MediaSizeDetails]

        enum CodingKeys: String, CodingKey {
            case width
            case height
            case fileName = "file"
            case sizes
        }
    }

    /// Details about a size of WordPress site media (e.g. `thumbnail`, `medium`, `2048x2048`).
    struct MediaSizeDetails: Decodable, Equatable {
        public let fileName: String
        public let src: String
        public let width: Double
        public let height: Double

        enum CodingKeys: String, CodingKey {
            case fileName = "file"
            case src = "source_url"
            case width
            case height
        }
    }

    /// Title of the WordPress site media.
    struct MediaTitle: Decodable, Equatable {
        /// `GET` media list request's `title` field only contains `rendered`, while `POST` media request includes both `raw` and `rendered`.
        let rendered: String

        enum CodingKeys: String, CodingKey {
            case rendered
        }
    }
}

private extension WordPressMedia {
    enum CodingKeys: String, CodingKey {
        case mediaID  = "id"
        case date = "date_gmt"
        case slug
        case mimeType = "mime_type"
        case src = "source_url"
        case alt = "alt_text"
        case details = "media_details"
        case title
    }
}
