import Foundation

/// Mapper for `WordPressSite`.
///
struct WordPressSiteMapper: Mapper {
    var validateAuthorization = false

    func map(response: Data) throws -> WordPressSite {
        if validateAuthorization,
           let root = try JSONSerialization.jsonObject(with: response) as? [String: Any],
           let authentication = root["authentication"] {
            let emptyArray = (authentication as? [Any])?.isEmpty == true
            let auth = authentication as? [String: Any]
            if !emptyArray && auth == nil {
                throw invalidAuthorization()
            }
            if let advertised = auth?["application-passwords"] {
                guard let feature = advertised as? [String: Any],
                      let endpoints = feature["endpoints"] as? [String: Any],
                      let value = endpoints["authorization"] as? String,
                      let url = URL(string: value),
                      ["http", "https"].contains(url.scheme?.lowercased()),
                      url.host != nil else {
                    throw invalidAuthorization()
                }
            }
        }
        let decoder = JSONDecoder()
        return try decoder.decode(WordPressSite.self, from: response)
    }

    private func invalidAuthorization() -> UnexpectedStoreResponseError {
        UnexpectedStoreResponseError(kind: .unexpectedContent)
    }
}
