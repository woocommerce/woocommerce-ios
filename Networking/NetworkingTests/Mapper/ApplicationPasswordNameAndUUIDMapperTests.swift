import XCTest
@testable import Networking

/// ApplicationPasswordNameAndUUIDMapper Unit Tests
///
final class ApplicationPasswordNameAndUUIDMapperTests: XCTestCase {
    /// Verifies that GET application password response is parsed properly
    ///
    func test_response_is_properly_parsed_when_loading_all_application_passwords() throws {
        guard let passwords = mapGetApplicationPasswordsResponse() else {
            XCTFail()
            return
        }

        let password = try XCTUnwrap(passwords.first)
        XCTAssertEqual(password.uuid, "42467857-579d-4bf3-8cc7-88bfb701d3a7")
        XCTAssertEqual(password.name, "testest")
    }
}

// MARK: - Private Methods.
//
private extension ApplicationPasswordNameAndUUIDMapperTests {

    /// Returns the ApplicationPasswordNameAndUUIDMapper output upon receiving success response
    ///
    func mapGetApplicationPasswordsResponse() -> [ApplicationPasswordNameAndUUID]? {
        guard let response = Loader.contentsOf("get-application-passwords-success") else {
            return nil
        }

        return try? ApplicationPasswordNameAndUUIDMapper().map(response: response)
    }
}
