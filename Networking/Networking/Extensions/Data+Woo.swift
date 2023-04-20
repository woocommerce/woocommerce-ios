import Foundation

extension Data {
    /// Checks whether the JSON data has a `data` key at the root.
    ///
    var hasDataEnvelope: Bool {
        let decoder = JSONDecoder()
        do {
            _ = try decoder.decode(ContentEnvelope.self, from: self)
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
