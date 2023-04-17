import Foundation


/// Mapper: Country Collection
///
struct CountryListMapper: Mapper {

    let siteID: Int64

    /// (Attempts) to convert an instance of Data into an array of Country Entities.
    ///
    func map(response: Data) throws -> [Country] {
        guard siteID != WooConstants.placeholderSiteID else {
            return try JSONDecoder().decode([Country].self, from: response)
        }
        return try JSONDecoder().decode(CountryListEnvelope.self, from: response).data
    }
}


/// CountryListEnvelope Disposable Entity:
/// This entity allows us to parse [Country] with JSONDecoder.
///
private struct CountryListEnvelope: Decodable {
    let data: [Country]

    private enum CodingKeys: String, CodingKey {
        case data
    }
}
