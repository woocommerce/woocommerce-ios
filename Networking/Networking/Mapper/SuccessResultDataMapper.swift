import Foundation


/// Mapper: Success Result Wrapped in `data` Key
///
struct SuccessDataResultMapper: Mapper {

    /// (Attempts) to extract the `success` flag from a given JSON Encoded response.
    ///
    func map(response: Data) throws -> Bool {
        let dictionary = try JSONDecoder().decode(SuccessDataResultEnvelope.self, from: response).rawData
        guard let success = dictionary.first else {
            return false
        }
        return success.value
    }
}


/// SuccessDataResultEnvelope Disposable Entity
///
/// Some endpoints return a "success" response in the `data` key. This entity
/// allows us to parse that response with JSONDecoder.
///
private struct SuccessDataResultEnvelope: Decodable {
    let rawData: [String: Bool]

    private enum CodingKeys: String, CodingKey {
        case rawData = "data"
    }
}
