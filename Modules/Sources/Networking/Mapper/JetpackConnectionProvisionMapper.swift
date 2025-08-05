import Foundation

/// Mapper: Jetpack connection registration
///
struct JetpackConnectionProvisionMapper: Mapper {

    /// (Attempts) to extract the updated `currentUser` field from a given JSON Encoded response.
    ///
    func map(response: Data) throws -> JetpackConnectionProvisionResponse {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(JetpackConnectionProvisionResponse.self, from: response)
    }
}

public struct JetpackConnectionProvisionResponse: Decodable {
    public let userId: Int64
    public let scope: String
    public let secret: String
}
