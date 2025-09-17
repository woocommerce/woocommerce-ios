import Foundation

/// Wrapper type for flexible MetaData array decoding that supports both array and dictionary formats
public struct FlexibleMetaDataArray: Decodable {
    public let metadata: [MetaData]

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        // Try to decode as array first (standard format)
        if let metaDataArray = try? container.decode([MetaData].self) {
            self.metadata = metaDataArray
            return
        }

        // Try to decode as object keyed by index strings – this may happen when plugins break the response format
        if let metaDataDict = try? container.decode([String: MetaData].self) {
            self.metadata = Array(metaDataDict.values)
            return
        }

        // Fallback to empty array
        self.metadata = []
    }
}
