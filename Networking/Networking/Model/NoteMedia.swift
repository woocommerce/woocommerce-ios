import Foundation


// MARK: - NoteMedia
//
public struct NoteMedia: Equatable, GeneratedFakeable {

    /// NoteMedia.Type expressed as a Swift Native Enum.
    ///
    public let kind: Kind

    /// Media Type.
    ///
    public let type: String

    /// Media Range.
    ///
    public let range: NSRange

    /// Media Size.
    ///
    public let size: CGSize?

    /// Media URL.
    ///
    public let url: URL



    /// Designated Initializer.
    ///
    public init(type: String, range: NSRange, url: URL, size: CGSize?) {
        self.kind = Kind(rawValue: type) ?? .unknown
        self.type = type
        self.range = range
        self.url = url
        self.size = size
    }
}


// MARK: - Decodable Conformance
//
extension NoteMedia: Decodable {

    /// Decodable Initializer.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let type = try container.decode(String.self, forKey: .type)
        let range = try container.decode(arrayEncodedRangeForKey: .indices)
        let url = try container.decode(URL.self, forKey: .url)

        let size: CGSize? = {
            guard let width = container.failsafeDecodeIfPresent(integerForKey: .width),
                let height = container.failsafeDecodeIfPresent(integerForKey: .height) else {
                    return nil
            }

            return CGSize(width: width, height: height)
        }()

        self.init(type: type, range: range, url: url, size: size)
    }
}


// MARK: - Neated Types
//
extension NoteMedia {

    /// Coding Keys
    ///
    enum CodingKeys: String, CodingKey {
        case type
        case url
        case indices
        case width
        case height
    }

    /// Known kinds of Media Types
    ///
    public enum Kind: String {
        case image
        case badge
        case unknown
    }
}


// MARK: - Equatable Conformance
//
public func ==(lhs: NoteMedia, rhs: NoteMedia) -> Bool {
    return lhs.type == rhs.type &&
            lhs.range == rhs.range &&
            lhs.size == rhs.size &&
            lhs.url == rhs.url
}
