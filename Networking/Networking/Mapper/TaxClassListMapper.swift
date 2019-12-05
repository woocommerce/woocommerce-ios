import Foundation


/// Mapper: TaxClass List
///
struct TaxClassListMapper: Mapper {

    /// (Attempts) to convert a dictionary into [TaxClass].
    ///
    func map(response: Data) throws -> [TaxClass] {
        let decoder = JSONDecoder()
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
