import XCTest
@testable import Networking

/// JetpackUserMapper Unit Tests
///
final class JetpackUserMapperTests: XCTestCase {

    func test_all_fields_are_parsed_properly_when_user_is_connected() throws {
        // Given
        let user = try mapUserFromMockResponse()
        let wpcomUser = try XCTUnwrap(user.wpcomUser)

        // Then
        XCTAssertEqual(user.username, "admin")
        XCTAssertEqual(user.gravatar, "<img alt='' src='http://2.gravatar.com/avatar/5e1a8fhjd'/>")
        XCTAssertTrue(user.isPrimary)
        XCTAssertTrue(user.isConnected)

        XCTAssertEqual(wpcomUser.id, 223)
        XCTAssertEqual(wpcomUser.username, "test")
        XCTAssertEqual(wpcomUser.email, "test@gmail.com")
        XCTAssertEqual(wpcomUser.displayName, "Test")
        XCTAssertEqual(wpcomUser.avatar, "http://2.gravatar.com/avatar/5e1a8fhjd")
    }

    func test_all_fields_are_parsed_properly_when_user_is_not_connected() throws {
        // Given
        let user = try mapNotConnectedUserFromMockResponse()

        // Then
        XCTAssertFalse(user.isPrimary)
        XCTAssertFalse(user.isConnected)
        XCTAssertEqual(user.username, "test")
        XCTAssertEqual(user.gravatar, "https://secure.gravatar.com/avatar/a7839e14")
        XCTAssertNil(user.wpcomUser)
    }
}

private extension JetpackUserMapperTests {
    func mapUserFromMockResponse() throws -> JetpackUser {
        guard let response = Loader.contentsOf("jetpack-connected-user") else {
            throw FileNotFoundError()
        }

        return try JetpackUserMapper().map(response: response)
    }

    func mapNotConnectedUserFromMockResponse() throws -> JetpackUser {
        guard let response = Loader.contentsOf("jetpack-user-not-connected") else {
            throw FileNotFoundError()
        }

        return try JetpackUserMapper().map(response: response)
    }

    struct FileNotFoundError: Error {}
}
