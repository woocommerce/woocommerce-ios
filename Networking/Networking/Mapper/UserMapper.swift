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

        if response.hasDataEnvelope {
            return try decoder.decode(UserEnvelope.self, from: response).user
        } else {
            return try decoder.decode(User.self, from: response)
        }
    }
}

/// UserEnvelope Disposable Entity
///
/// `Load User` endpoint returns the requested objects in the `data` key. This entity
/// allows us to parse all the things with JSONDecoder.
///
private struct UserEnvelope: Decodable {
    let user: User

    private enum CodingKeys: String, CodingKey {
        case user = "data"
    }
}
