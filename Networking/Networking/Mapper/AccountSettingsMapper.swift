import Foundation


/// Mapper: AccountSettings
///
class AccountSettingsMapper: Mapper {

    /// (Attempts) to convert a dictionary into an AccountSettings entity.
    ///
    func map(response: Data) throws -> AccountSettings {
        let decoder = JSONDecoder()
        return try decoder.decode(AccountSettings.self, from: response)
    }
}
