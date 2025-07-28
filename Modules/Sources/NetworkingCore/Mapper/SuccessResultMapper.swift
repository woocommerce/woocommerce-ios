import Foundation


/// Mapper: Success Result
///
public struct SuccessResultMapper: Mapper {

    public init() {}

    /// (Attempts) to extract the `success` flag from a given JSON Encoded response.
    ///
    public func map(response: Data) throws -> Bool {
        return try JSONDecoder().decode(SuccessResult.self, from: response).success
    }
}


/// Success Flag Envelope
///
private struct SuccessResult: Decodable {

    /// Success Flag
    ///
    let success: Bool

    /// Coding Keys!
    ///
    private enum CodingKeys: String, CodingKey {
        case success
    }
}
