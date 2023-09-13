import Foundation

/// Mapper: TaxRate
///
struct TaxRateMapper: Mapper {

    /// Site Identifier associated to the taxRate that will be parsed.
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because SiteID is not returned in any of the TaxRate Endpoints.
    ///
    let siteID: Int64


    /// (Attempts) to convert a dictionary into TaxRate.
    ///
    func map(response: Data) throws -> TaxRate {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)
        decoder.userInfo = [
            .siteID: siteID
        ]

        if hasDataEnvelope(in: response) {
            return try decoder.decode(TaxRateEnvelope.self, from: response).taxRate
        } else {
            return try decoder.decode(TaxRate.self, from: response)
        }
    }
}


/// TaxRate Envelope Disposable Entity
///
/// `Load TaxRate` endpoint returns the requested taxRate document in the `data` key. This entity
/// allows us to do parse all the things with JSONDecoder.
///
private struct TaxRateEnvelope: Decodable {
    let taxRate: TaxRate

    private enum CodingKeys: String, CodingKey {
        case taxRate = "data"
    }
}
