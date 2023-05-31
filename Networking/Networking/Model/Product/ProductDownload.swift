import Foundation
import Codegen

/// Represents a ProductDownload entity.
///
public struct ProductDownload: Codable, Equatable, GeneratedFakeable {
    public let downloadID: String
    public let name: String?
    public let fileURL: String?

    /// ProductDownload initializer.
    ///
    public init(downloadID: String,
                name: String?,
                fileURL: String?) {
        self.downloadID = downloadID
        self.name = name
        self.fileURL = fileURL
    }

    /// Public initializer for ProductDownload
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Even though a plain install of WooCommerce Core provides String values,
        // some plugins alter the field value from String to Int or Decimal.
        let downloadID = container.failsafeDecodeIfPresent(targetType: String.self,
                                                           forKey: .downloadID,
                                                           alternativeTypes: [.decimal(transform: { NSDecimalNumber(decimal: $0).stringValue })]) ?? "0"
        let name = try container.decodeIfPresent(String.self, forKey: .name)
        let fileURL = try container.decodeIfPresent(String.self, forKey: .fileURL)

        self.init(downloadID: downloadID,
                  name: name,
                  fileURL: fileURL)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(downloadID, forKey: .downloadID)
        try container.encode(name, forKey: .name)
        try container.encode(fileURL, forKey: .fileURL)
    }
}


/// Defines all the ProductDownload CodingKeys.
///
private extension ProductDownload {
    enum CodingKeys: String, CodingKey {
        case downloadID = "id"
        case name       = "name"
        case fileURL    = "file"
    }
}
