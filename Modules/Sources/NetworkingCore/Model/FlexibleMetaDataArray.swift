import Foundation

/// Helper for flexible MetaData array decoding that supports both array and dictionary formats
public enum FlexibleMetaDataDecoder {

    /// Decodes metadata from a KeyedDecodingContainer with flexible support for both array and dictionary formats
    /// - Parameters:
    ///   - container: The KeyedDecodingContainer to decode from
    ///   - key: The key for the metadata field
    /// - Returns: Array of MetaData objects, empty array if decoding fails
    public static func decode<K>(from container: KeyedDecodingContainer<K>,
                                 forKey key: KeyedDecodingContainer<K>.Key) -> [MetaData] {
        // Try to decode as array first (standard format)
        if let metaDataArray = try? container.decode([MetaData].self, forKey: key) {
            return metaDataArray
        }

        // Try to decode as object keyed by index strings – this may happen when plugins break the response format
        if let metaDataDict = try? container.decode([String: MetaData].self, forKey: key) {
            return Array(metaDataDict.values)
        }

        // Fallback to empty array
        return []
    }
}

/// Wrapper type for flexible MetaData array decoding when the entire decoder is for metadata
/// This type is designed for cases like ProductMetadataExtractor that decode from the whole product JSON
public struct FlexibleMetaDataArray: Decodable {
    public let metadata: [MetaData]

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.metadata = FlexibleMetaDataDecoder.decode(from: container, forKey: .metadata)
    }

    private enum CodingKeys: String, CodingKey {
        case metadata = "meta_data"
    }
}
