import Foundation


/// Mapper: MetaData List
///
struct MetaDataMapper: Mapper {

    /// (Attempts) to convert an instance of Data into an array of MetaData Entities.
    ///
    func map(response: Data) throws -> [MetaData] {
        let decoder = JSONDecoder()
        let envelope = try decoder.decode(MetaDataEnvelope.self, from: response)

        // Filter out metadata if the key is prefixed with an underscore (internal meta keys)
        return envelope.metadata.filter { !$0.key.hasPrefix("_") }
    }
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
