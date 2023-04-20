import Foundation

/// Mapper: Bool Result, Wrapped in `data` Key or not
///
struct DataBoolMapper: Mapper {

    /// (Attempts) to extract the boolean flag from a given JSON Encoded response.
    ///
    func map(response: Data) throws -> Bool {
        if response.hasDataEnvelope {
            return try JSONDecoder().decode(DataBool.self, from: response).data
        } else {
            return try JSONDecoder().decode(Bool.self, from: response)
        }
    }
}

/// DataBoolResultEnvelope Disposable Entity
///
/// Some endpoints return a Bool response in the `data` key. This entity
/// allows us to parse that response with JSONDecoder.
///
private struct DataBool: Decodable {
    let data: Bool

    private enum CodingKeys: String, CodingKey {
        case data
    }
}
