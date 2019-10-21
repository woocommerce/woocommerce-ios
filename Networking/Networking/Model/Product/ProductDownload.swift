import Foundation

/// Represents a ProductDownload entity.
///
public struct ProductDownload: Decodable {
    public let downloadID: String
    public let name: String?
    public let fileURL: String?

    /// ProductDownload initializer.
    ///
    public init(
        downloadID: String,
        name: String?,
        fileURL: String?
    ) {
        self.downloadID = downloadID
        self.name = name
        self.fileURL = fileURL
    }

    /// Public initializer for ProductDownload
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let downloadID = try container.decode(String.self, forKey: .downloadID)
        let name = try container.decodeIfPresent(String.self, forKey: .name)
        let fileURL = try container.decodeIfPresent(String.self, forKey: .fileURL)

        self.init(
            downloadID: downloadID,
            name: name,
            fileURL: fileURL)
    }
}


/// Defines all the ProductDownload CodingKeys.
///
extension ProductDownload {
    fileprivate enum CodingKeys: String, CodingKey {
        case downloadID = "id"
        case name = "name"
        case fileURL = "file"
    }
}


// MARK: - Comparable Conformance
//
extension ProductDownload: Comparable {
    public static func == (lhs: ProductDownload, rhs: ProductDownload) -> Bool {
        return lhs.downloadID == rhs.downloadID && lhs.name == rhs.name && lhs.fileURL == rhs.fileURL
    }

    public static func < (lhs: ProductDownload, rhs: ProductDownload) -> Bool {
        return lhs.downloadID < rhs.downloadID
    }
}
