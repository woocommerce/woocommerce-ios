import Foundation


/// Mapper: TaxClass List
///
struct TaxClassListMapper: Mapper {

    /// Site Identifier associated to the API information that will be parsed.
    /// We're injecting this field via `JSONDecoder.userInfo` because the remote endpoints don't return the SiteID.
    ///
    let siteID: Int64

    /// (Attempts) to convert a dictionary into [TaxClass].
    ///
    func map(response: Data) throws -> [TaxClass] {
        let decoder = JSONDecoder()
        decoder.userInfo = [
            .siteID: siteID
        ]

        return try decoder.decode(TaxClassListEnvelope.self, from: response).taxClasses
    }
}


/// TaxClassListEnvelope Disposable Entity:
/// `Load All Tax Classes` endpoint returns the tax classes document in the `data` key.
/// This entity allows us to do parse all the things with JSONDecoder.
///
private struct TaxClassListEnvelope: Decodable {
    let taxClasses: [TaxClass]

    private enum CodingKeys: String, CodingKey {
        case taxClasses = "data"
    }
}
