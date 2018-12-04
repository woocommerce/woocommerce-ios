import Foundation


/// Mapper: SitePlan
///
class SitePlanMapper: Mapper {

    /// (Attempts) to convert a dictionary into a site plan attribute for the site entity.
    ///
    func map(response: Data) throws -> SitePlan {
        let decoder = JSONDecoder()
        return try decoder.decode(SitePlan.self, from: response)
    }
}
