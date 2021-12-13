import XCTest
@testable import Networking


/// AccountSettingsMapper Unit Tests
///
class AccountSettingsMapperTests: XCTestCase {

    /// Verifies that all of the AccountSettings fields are properly parsed.
    ///
    func test_Account_fields_are_properly_parsed() {
        guard let account = mapLoadAccountSettingsResponse() else {
            XCTFail()
            return
        }

        XCTAssertEqual(account.userID, 10)
        XCTAssertTrue(account.tracksOptOut)
        XCTAssertEqual(account.firstName, "Dem 123")
        XCTAssertEqual(account.lastName, "Nines")
    }
}



// MARK: - Private Methods.
//
private extension AccountSettingsMapperTests {

    /// Returns the AccountSettingsMapper output upon receiving `me-settings` mock response (Data Encoded).
    ///
    func mapLoadAccountSettingsResponse() -> AccountSettings? {
        guard let response = Loader.contentsOf("me-settings") else {
            return nil
        }

        return try? AccountSettingsMapper(userID: 10).map(response: response)
    }
}
