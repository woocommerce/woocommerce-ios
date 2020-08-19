import XCTest
@testable import Networking


/// AccountSettingsMapper Unit Tests
///
class AccountSettingsMapperTests: XCTestCase {

    /// Verifies that all of the AccountSettings fields are properly parsed.
    ///
    func test_Account_fields_are_propertly_parsed() {
        guard let account = mapLoadAccountSettingsResponse() else {
            XCTFail()
            return
        }

        XCTAssertEqual(account.userID, 10)
        XCTAssertTrue(account.tracksOptOut)
    }
}



// MARK: - Private Methods.
//
private extension AccountSettingsMapperTests {

    /// Returns the AccountSettingsMapper output upon receiving `me-settings` mockup response (Data Encoded).
    ///
    func mapLoadAccountSettingsResponse() -> AccountSettings? {
        guard let response = Loader.contentsOf("me-settings") else {
            return nil
        }

        return try? AccountSettingsMapper(userID: 10).map(response: response)
    }
}
