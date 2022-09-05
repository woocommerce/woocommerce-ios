import Foundation

/// Mapper: Jetpack connected user
///
struct JetpackConnectedUserMapper: Mapper {

    /// (Attempts) to extract the updated `currentUser` field from a given JSON Encoded response.
    ///
    func map(response: Data) throws -> JetpackConnectedUser {

        let decoder = JSONDecoder()
        return try decoder.decode(JetpackConnectedData.self, from: response).currentUser
    }
}

/// JetpackConnectedData Disposable Entity:
/// This entity allows us to parse JetpackConnectedUser with JSONDecoder.
///
private struct JetpackConnectedData: Decodable {
    let currentUser: JetpackConnectedUser

    private enum CodingKeys: String, CodingKey {
        case currentUser
    }
}
