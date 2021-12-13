import Foundation

/// Mapper: User
///
struct UserMapper: Mapper {
    /// Site Identifier associated to the order that will be parsed.
    /// We're injecting this field via `JSONDecoder.userInfo` because SiteID is not returned in the endpoints used to retrieve User models.
    ///
    let siteID: Int64

    /// (Attempts) to convert a dictionary into User.
    ///
    func map(response: Data) throws -> User {
        let decoder = JSONDecoder()
        decoder.userInfo = [
            .siteID: siteID
        ]

        return try decoder.decode(User.self, from: response)
    }
}
