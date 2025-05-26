import Foundation

/// Mapper: TaxRate List
///
struct TaxRateListMapper: Mapper {

    /// Site Identifier associated to the API information that will be parsed.
    /// We're injecting this field via `JSONDecoder.userInfo` because the remote endpoints don't return the SiteID.
    ///
    let siteID: Int64

    /// (Attempts) to convert a dictionary into [TaxRate].
    ///
    func map(response: Data) throws -> [TaxRate] {
        let decoder = JSONDecoder()
        decoder.userInfo = [
            .siteID: siteID
        ]

        if hasDataEnvelope(in: response) {
            return try decoder.decode(TaxRateListEnvelope.self, from: response).taxClasses
        } else {
            return try decoder.decode([TaxRate].self, from: response)
        }
    }
}

/// TaxRateListEnvelope Disposable Entity:
/// `Load All Tax Rates` endpoint returns the tax rates document in the `data` key.
/// This entity allows us to do parse all the things with JSONDecoder.
///
private struct TaxRateListEnvelope: Decodable {
    let taxClasses: [TaxRate]

    private enum CodingKeys: String, CodingKey {
        case taxClasses = "data"
    }
}
