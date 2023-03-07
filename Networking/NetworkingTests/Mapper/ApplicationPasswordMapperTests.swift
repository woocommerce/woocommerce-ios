import XCTest
@testable import Networking


/// ApplicationPasswordMapper Unit Tests
///
final class ApplicationPasswordMapperTests: XCTestCase {

    private let wpOrgUsername = "username"

    /// Verifies that generate password using WPCOM token response is parsed properly
    ///
    func test_response_is_properly_parsed_while_generating_password_using_WPCOM_token() {
        guard let password = mapGenerateUsingWPOrgResponse() else {
            XCTFail()
            return
        }

        XCTAssertEqual(password.password.secretValue, "passwordvalue")
        XCTAssertEqual(password.uuid, "8ef68e6b-4670-4cfd-8ca0-456e616bcd5e")
        XCTAssertEqual(password.wpOrgUsername, "username")
    }
}

// MARK: - Private Methods.
//
private extension ApplicationPasswordMapperTests {

    /// Returns the ApplicationPasswordMapper output upon receiving success response
    ///
    func mapGenerateUsingWPOrgResponse() -> ApplicationPassword? {
        guard let response = Loader.contentsOf("generate-application-password-using-wporg-creds-success") else {
            return nil
        }

        return try? ApplicationPasswordMapper(wpOrgUsername: wpOrgUsername).map(response: response)
    }
}
