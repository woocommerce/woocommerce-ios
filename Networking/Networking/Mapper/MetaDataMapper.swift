import Foundation

/// Mapper: MetaData List
///
struct MetaDataMapper: Mapper {

    /// (Attempts) to convert an instance of Data into an array of MetaData Entities.
    ///
    func map(response: Data) throws -> [MetaData] {
        let decoder = JSONDecoder()
        if hasDataEnvelope(in: response) {
            let envelope = try decoder.decode(DataEnvelope.self, from: response)
            return envelope.data.metadata.filter { !$0.key.hasPrefix("_") }
        } else {
            let envelope = try decoder.decode(MetaDataEnvelope.self, from: response)
            return envelope.metadata.filter { !$0.key.hasPrefix("_") }
        }
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
}
