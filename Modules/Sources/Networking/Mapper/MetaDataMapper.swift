import Foundation

/// Mapper: MetaData List
///
struct MetaDataMapper: Mapper {

    /// (Attempts) to convert an instance of Data into an array of MetaData Entities.
    ///
    func map(response: Data) throws -> [MetaData] {
        let decoder = JSONDecoder()
        let metadata = try {
            if hasDataEnvelope(in: response) {
                let envelope = try decoder.decode(DataEnvelope.self, from: response)
                return envelope.data.metadata
            } else {
                let envelope = try decoder.decode(MetaDataEnvelope.self, from: response)
                return envelope.metadata
            }
        }()
        // Filter out metadata if the key is prefixed with an underscore (internal meta keys)
        return metadata.filter { !$0.key.hasPrefix("_") }
    }

    /// Decodes MetaData from a KeyedDecodingContainer with flexible support for both array and dictionary formats
    /// - Parameters:
    ///   - container: The KeyedDecodingContainer to decode from
    ///   - key: The key for the metadata field
    ///   - filterInternalKeys: Whether to filter out keys that start with "_" (default: true)
    /// - Returns: Array of MetaData objects
    static func decodeMetaData<K>(from container: KeyedDecodingContainer<K>,
                                  forKey key: KeyedDecodingContainer<K>.Key,
                                  filterInternalKeys: Bool = true) -> [MetaData] {
        let metadata: [MetaData] = {
            // Try to decode as array first (standard format)
            if let metaDataArray = try? container.decode([MetaData].self, forKey: key) {
                return metaDataArray
            }

            // Try to decode as object keyed by index strings – this may happen when plugins break the response format
            if let metaDataDict = try? container.decode([String: MetaData].self, forKey: key) {
                return Array(metaDataDict.values)
            }

            return []
        }()

        return filterInternalKeys ? metadata.filter { !$0.key.hasPrefix("_") } : metadata
    }

}

/// DataEnvelope Entity:
/// This entity allows us to parse the metadata from the JSON response using JSONDecoder.
///
private struct DataEnvelope: Decodable {
    let data: MetaDataEnvelope
}

/// MetaDataEnvelope Entity:
/// This entity allows us to parse the metadata from the JSON response using JSONDecoder.
///
private struct MetaDataEnvelope: Decodable {
    let metadata: [MetaData]

    private enum CodingKeys: String, CodingKey {
        case metadata = "meta_data"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.metadata = MetaDataMapper.decodeMetaData(from: container, forKey: .metadata, filterInternalKeys: false)
    }
}
