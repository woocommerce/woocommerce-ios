import Foundation

/// Mapper: BlazeImpressions
///
struct BlazeImpressionsMapper: Mapper {
    
    /// (Attempts) to convert a dictionary into a BlazeImpressions entity
    ///
    func map(response: Data) throws -> BlazeImpressions {
        let decoder = JSONDecoder()
        return try decoder.decode(BlazeImpressions.self, from: response)
    }
}
