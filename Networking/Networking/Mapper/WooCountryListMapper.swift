import Foundation


/// Mapper: WooCountry Collection
///
struct WooCountryListMapper: Mapper {

    /// (Attempts) to convert an instance of Data into an array of WooCountry Entities.
    ///
    func map(response: Data) throws -> [WooCountry] {
        return try JSONDecoder().decode(WooCountryListEnvelope.self, from: response).data
    }
}


/// WooCountryListEnvelope Disposable Entity:
/// This entity allows us to parse [Country] with JSONDecoder.
///
private struct WooCountryListEnvelope: Decodable {
    let data: [WooCountry]

    private enum CodingKeys: String, CodingKey {
        case data
    }
}
