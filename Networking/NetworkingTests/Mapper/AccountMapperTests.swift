import XCTest
@testable import Networking


/// AccountMapper Unit Tests
///
class AccountMapperTests: XCTestCase {

    /// Verifies that all of the Account fields are properly parsed.
    ///
    func testAccountFieldsArePropertlyParsed() {
        guard let account = mapLoadAccountResponse() else {
            XCTFail()
            return
        }

        XCTAssertEqual(account.displayName, "apiexamples")
        XCTAssertEqual(account.email, "example@example.blog")
        XCTAssertEqual(account.gravatarUrl, "https://1.gravatar.com/avatar/a2afb7b6c0e23e5d363d8612fb1bd5ad?s=96&d=identicon&r=G")
        XCTAssertEqual(account.userID, 78972699)
        XCTAssertEqual(account.username, "apiexamples")
    }
}



// MARK: - Private Methods.
//
private extension AccountMapperTests {

    /// Returns the AccountMapper output upon receiving `me` (Data Encoded)
    ///
    func mapLoadAccountResponse() -> Account? {
        guard let response = Loader.contentsOf("me") else {
            return nil
        }

        return try? AccountMapper().map(response: response)
    }
}
