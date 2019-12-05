import Foundation


/// Mapper: TaxClass
///
struct TaxClassMapper: Mapper {

    /// (Attempts) to convert a dictionary into a Tax Class entity.
    ///
    func map(response: Data) throws -> TaxClass {
        let decoder = JSONDecoder()
        return try decoder.decode(TaxClass.self, from: response)
    }
}
