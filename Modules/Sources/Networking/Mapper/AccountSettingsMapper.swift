import Foundation


/// Mapper: AccountSettings
///
struct AccountSettingsMapper: Mapper {

    /// User Identifier associated to the account settings that will be parsed.
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because UserID is not returned in the /me/settings endpoint.
    ///
    let userID: Int64

    /// (Attempts) to convert a dictionary into an AccountSettings entity.
    ///
    func map(response: Data) throws -> AccountSettings {
        let decoder = JSONDecoder()
        decoder.userInfo = [
            .userID: userID
        ]

        return try decoder.decode(AccountSettings.self, from: response)
    }
}
