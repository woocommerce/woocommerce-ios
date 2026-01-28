import Foundation

/// Mapper: Jetpack connection registration
///
/// periphery: ignore - used in `JetpackConnectionRemote`
public struct JetpackConnectionProvisionMapper: Mapper {

    public init() {}

    /// (Attempts) to extract the updated `currentUser` field from a given JSON Encoded response.
    ///
    public func map(response: Data) throws -> JetpackConnectionProvisionResponse {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(JetpackConnectionProvisionResponse.self, from: response)
    }
}

public struct JetpackConnectionProvisionResponse: Decodable {
    public let userId: Int64
    public let scope: String
    public let secret: String

    /// periphery: ignore - used in test module
    public init(userId: Int64, scope: String, secret: String) {
        self.userId = userId
        self.scope = scope
        self.secret = secret
    }
}
