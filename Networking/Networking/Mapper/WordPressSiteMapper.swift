import Foundation

/// Mapper for `WordPressSite`.
///
struct WordPressSiteMapper: Mapper {

    func map(response: Data) async throws -> WordPressSite {
        let decoder = JSONDecoder()
        return try decoder.decode(WordPressSite.self, from: response)
    }
}
