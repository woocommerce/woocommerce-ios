import XCTest
@testable import Networking


/// ApplicationPasswordMapper Unit Tests
///
final class ApplicationPasswordMapperTests: XCTestCase {

    /// Verifies that generate password using WPCOM token response is parsed properly
    ///
    func test_response_is_properly_parsed_while_generating_password_using_WPCOM_token() {
        guard let password = mapGenerateUsingWPOrgResponse() else {
            XCTFail()
            return
        }

        XCTAssertEqual(password, "passwordvalue")
    }
}

// MARK: - Private Methods.
//
private extension ApplicationPasswordMapperTests {

    /// Returns the ApplicationPasswordMapper output upon receiving success response
    ///
    func mapGenerateUsingWPOrgResponse() -> String? {
        guard let response = Loader.contentsOf("generate-application-password-using-wporg-creds-success") else {
            return nil
        }

        return try? ApplicationPasswordMapper().map(response: response)
    }
}
