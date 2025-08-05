import Foundation

/// Mapper: Jetpack connection registration
///
struct JetpackConnectionResultMapper: Mapper {

    /// (Attempts) to extract the updated `currentUser` field from a given JSON Encoded response.
    ///
    func map(response: Data) throws -> JetpackConnectionResult {
        let decoder = JSONDecoder()
        return try decoder.decode(JetpackConnectionResult.self, from: response)
    }
}

struct JetpackConnectionResult: Decodable {
    let code: String
    let message: String
}
