import Foundation

/// Mapper: Jetpack connection registration
///
/// periphery: ignore - used in `JetpackConnectionRemote`
struct JetpackConnectionRegistrationMapper: Mapper {

    /// (Attempts) to extract the updated `currentUser` field from a given JSON Encoded response.
    ///
    func map(response: Data) throws -> JetpackConnectionRegistration {
        let decoder = JSONDecoder()
        return try decoder.decode(JetpackConnectionRegistration.self, from: response)
    }
}

struct JetpackConnectionRegistration: Decodable {
    let authorizeUrl: String
}
