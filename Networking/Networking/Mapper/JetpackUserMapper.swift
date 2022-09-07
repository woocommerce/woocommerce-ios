import Foundation

/// Mapper: Jetpack user
///
struct JetpackUserMapper: Mapper {

    /// (Attempts) to extract the updated `currentUser` field from a given JSON Encoded response.
    ///
    func map(response: Data) throws -> JetpackUser {
        let decoder = JSONDecoder()
        return try decoder.decode(JetpackConnectionData.self, from: response).currentUser
    }
}

/// JetpackConnectionData Disposable Entity:
/// This entity allows us to parse JetpackUser with JSONDecoder.
///
private struct JetpackConnectionData: Decodable {
    let currentUser: JetpackUser

    private enum CodingKeys: String, CodingKey {
        case currentUser
    }
}
