import Foundation


/// Mapper: Success Result Wrapped in `data` Key
///
struct SuccessDataResultMapper: Mapper {

    /// (Attempts) to extract the `success` flag from a given JSON Encoded response.
    ///
    func map(response: Data) throws -> Bool {
        let decoder = JSONDecoder()
        let rawData: [String: Bool] = try {
            if hasDataEnvelope(in: response) {
                return try decoder.decode(SuccessDataResultEnvelope.self, from: response).rawData
            } else {
                return try decoder.decode([String: Bool].self, from: response)
            }
        }()
        return rawData["success"] ?? false
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
