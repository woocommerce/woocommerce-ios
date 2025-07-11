import Foundation

/// SingleItemMapper: Maps generic REST API requests for a single item
///
public struct SingleItemMapper<Output: Decodable>: Mapper {
    /// Site Identifier associated to the items that will be parsed.
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because SiteID is not returned by our endpoints.
    ///
    let siteID: Int64

    public init(siteID: Int64) {
        self.siteID = siteID
    }

    /// (Attempts) to convert a dictionary into Output.
    ///
    public func map(response: Data) throws -> Output {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)
        decoder.userInfo = [
            .siteID: siteID
        ]

        if hasDataEnvelope(in: response) {
            return try decoder.decode(SingleItemEnvelope<Output>.self, from: response).item
        } else {
            return try decoder.decode(Output.self, from: response)
        }
    }
}

/// SingleItemEnvelope Disposable Entity:
/// Our list endpoints return the item in the `data` key.
/// This entity allows us to do parse all the things with JSONDecoder.
///
private struct SingleItemEnvelope<Output: Decodable>: Decodable {
    let item: Output

    private enum CodingKeys: String, CodingKey {
        case item = "data"
    }
}
