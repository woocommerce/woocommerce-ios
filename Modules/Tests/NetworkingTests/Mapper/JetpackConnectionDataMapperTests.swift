import XCTest
@testable import Networking
@testable import NetworkingCore

/// JetpackUserMapper Unit Tests
///
final class JetpackConnectionDataMapperTests: XCTestCase {

    func test_all_fields_are_parsed_properly_when_user_is_connected() throws {
        // Given
        let data = try mapUserFromMockResponse()
        let user = data.currentUser
        let wpcomUser = try XCTUnwrap(user.wpcomUser)

        // Then
        XCTAssertEqual(data.isRegistered, true)
        XCTAssertEqual(data.connectionOwner, "testuser")
        XCTAssertEqual(data.blogID, 1244634)

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

    func test_all_fields_are_parsed_properly_when_response_has_data_envelope() throws {
        // Given
        let data = try mapUserFromEnvelopedMockResponse()
        let user = data.currentUser
        let wpcomUser = try XCTUnwrap(user.wpcomUser)

        // Then
        XCTAssertEqual(data.isRegistered, true)
        XCTAssertEqual(data.connectionOwner, "testuser")
        XCTAssertEqual(data.blogID, 1244634)

        XCTAssertEqual(user.username, "admin")
        XCTAssertTrue(user.isPrimary)
        XCTAssertTrue(user.isConnected)

        XCTAssertEqual(wpcomUser.id, 223)
        XCTAssertEqual(wpcomUser.username, "test")
        XCTAssertEqual(wpcomUser.email, "test@gmail.com")
    }

    func test_all_fields_are_parsed_properly_when_user_is_not_connected() throws {
        // Given
        let data = try mapNotConnectedUserFromMockResponse()
        let user = data.currentUser

        // Then
        XCTAssertNil(data.isRegistered)
        XCTAssertEqual(data.connectionOwner, "demo")
        XCTAssertNil(data.blogID)

        XCTAssertFalse(user.isPrimary)
        XCTAssertFalse(user.isConnected)
        XCTAssertEqual(user.username, "test")
        XCTAssertEqual(user.gravatar, "https://secure.gravatar.com/avatar/a7839e14")
        XCTAssertNil(user.wpcomUser)
    }
}

private extension JetpackConnectionDataMapperTests {
    func mapUserFromMockResponse() throws -> JetpackConnectionData {
        guard let response = Loader.contentsOf("jetpack-connected-user") else {
            throw FileNotFoundError()
        }

        return try JetpackConnectionDataMapper().map(response: response)
    }

    func mapNotConnectedUserFromMockResponse() throws -> JetpackConnectionData {
        guard let response = Loader.contentsOf("jetpack-user-not-connected") else {
            throw FileNotFoundError()
        }

        return try JetpackConnectionDataMapper().map(response: response)
    }

    func mapUserFromEnvelopedMockResponse() throws -> JetpackConnectionData {
        guard let response = Loader.contentsOf("jetpack-connected-user-enveloped") else {
            throw FileNotFoundError()
        }

        return try JetpackConnectionDataMapper().map(response: response)
    }

    struct FileNotFoundError: Error {}
}
