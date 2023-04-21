import Foundation

extension Mapper {
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
    let content: AnyDecodable

    private enum CodingKeys: String, CodingKey {
        case content = "data"
    }
}
