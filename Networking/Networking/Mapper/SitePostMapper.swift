import Foundation


/// Mapper: SitePost
///
class SitePostMapper: Mapper {

    /// (Attempts) to convert a dictionary into a SitePost entity.
    ///
    func map(response: Data) throws -> SitePost {
        let decoder = JSONDecoder()
        return try decoder.decode(SitePost.self, from: response)
    }
}
