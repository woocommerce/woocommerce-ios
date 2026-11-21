import Foundation


/// Mapper: Token ID
///
public struct TokenIDMapper: Mapper {

    public init() {}

    /// Extracts token and optional blog IDs from a JSON response.
    ///
    public func map(response: Data) throws -> SelfDrivenPushRegistration {
        let decoder = JSONDecoder()
        if hasDataEnvelope(in: response) {
            return try decoder.decode(TokenIDEnvelope.self, from: response).tokenID.registration
        } else {
            return try decoder.decode(TokenID.self, from: response).registration
        }
    }
}

/// TokenIDEnvelope Disposable Entity
///
private struct TokenIDEnvelope: Decodable {
    let tokenID: TokenID

    private enum CodingKeys: String, CodingKey {
        case tokenID = "data"
    }
}

/// Success Flag Envelope
///
private struct TokenID: Decodable {

    /// Success Flag
    ///
    let id: Int64
    let blogID: Int64?

    var registration: SelfDrivenPushRegistration {
        SelfDrivenPushRegistration(tokenID: id, blogID: blogID)
    }

    /// Coding Keys!
    ///
    private enum CodingKeys: String, CodingKey {
        case id
        case blogID = "blog_id"
    }
}
