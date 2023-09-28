import Foundation


/// Mapper: Country Collection
///
struct CountryListMapper: Mapper {

    /// (Attempts) to convert an instance of Data into an array of Country Entities.
    ///
    func map(response: Data) throws -> [Country] {
        if hasDataEnvelope(in: response) {
            return try JSONDecoder().decode(Envelope<[Country]>.self, from: response).data
        } else {
            return try JSONDecoder().decode([Country].self, from: response)
        }
    }
}
