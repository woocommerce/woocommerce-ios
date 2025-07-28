import Foundation


/// Mapper: Account
///
class AccountMapper: Mapper {

    /// (Attempts) to convert a dictionary into an Account entity.
    ///
    func map(response: Data) throws -> Account {
        let decoder = JSONDecoder()
        return try decoder.decode(Account.self, from: response)
    }
}
