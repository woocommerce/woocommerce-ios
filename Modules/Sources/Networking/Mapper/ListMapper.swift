import Foundation

/// ListMapper: Maps generic WooCommerce REST API Lists
///
struct ListMapper<Output: Decodable>: Mapper {
    /// Site Identifier associated to the items that will be parsed.
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because SiteID is not returned by our endpoints.
    ///
    let siteID: Int64

    /// (Attempts) to convert a dictionary into [Output].
    ///
    func map(response: Data) throws -> [Output] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)
        decoder.userInfo = [
            .siteID: siteID
        ]

        if hasDataEnvelope(in: response) {
            return try decoder.decode(ListEnvelope<Output>.self, from: response).items
        } else {
            return try decoder.decode([Output].self, from: response)
        }
    }
}

/// ListEnvelope Disposable Entity:
/// Our list endpoints return the items in the `data` key.
/// This entity allows us to do parse all the things with JSONDecoder.
///
private struct ListEnvelope<Output: Decodable>: Decodable {
    let items: [Output]

    private enum CodingKeys: String, CodingKey {
        case items = "data"
    }
}
