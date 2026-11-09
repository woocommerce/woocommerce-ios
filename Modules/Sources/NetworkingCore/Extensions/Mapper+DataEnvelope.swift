import Foundation

public extension Mapper {
    /// Checks whether the JSON data has a `data` key at the root.
    ///
    func hasDataEnvelope(in response: Data) -> Bool {
        let decoder = JSONDecoder()
        do {
            _ = try decoder.decode(ContentEnvelope.self, from: response)
            return true
        } catch {
            return false
        }
    }
}

/// Helper struct to attempt parsing some JSON data with a `data` key at the root.
///
private struct ContentEnvelope: Decodable {
    private enum CodingKeys: String, CodingKey {
        case data
    }

    // Checks only the key: decoding the value builds a full tree that callers then decode again.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard container.contains(.data) else {
            throw DecodingError.keyNotFound(CodingKeys.data, .init(codingPath: decoder.codingPath, debugDescription: "Missing `data` key"))
        }
    }
}
