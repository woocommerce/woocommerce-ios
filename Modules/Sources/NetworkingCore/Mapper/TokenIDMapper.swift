import Foundation


/// Mapper: Token ID
///
public struct TokenIDMapper: Mapper {

    public init() {}

    /// (Attempts) to extract the `id` flag from a given JSON Encoded response.
    ///
    public func map(response: Data) throws -> Int64 {
        let decoder = JSONDecoder()
        if hasDataEnvelope(in: response) {
            return try decoder.decode(TokenIDEnvelope.self, from: response).tokenID.id
        } else {
            return try decoder.decode(TokenID.self, from: response).id
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

    /// Coding Keys!
    ///
    private enum CodingKeys: String, CodingKey {
        case id
    }
}
