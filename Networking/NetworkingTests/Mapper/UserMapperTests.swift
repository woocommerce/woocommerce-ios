import XCTest
@testable import Networking


/// UserMapper Unit Tests
///
final class UserMapperTests: XCTestCase {
    private let testSiteID: Int64 = 123

    func test_User_fields_are_properly_parsed_with_data_envelope() async {
        guard let user = await mapUserFromMockResponseWithDataEnvelope() else {
            XCTFail()
            return
        }

        XCTAssertEqual(user.localID, 1)
        XCTAssertEqual(user.username, "test-username")
        XCTAssertEqual(user.firstName, "Test")
        XCTAssertEqual(user.lastName, "User")
        XCTAssertEqual(user.email, "example@example.blog")
        XCTAssertEqual(user.nickname, "User's Nickname")
        XCTAssertEqual(user.roles, ["administrator"])
        XCTAssertEqual(user.siteID, testSiteID)
    }

    func test_User_fields_are_properly_parsed_without_data_envelope() async {
        guard let user = await mapUserFromMockResponseWithoutDataEnvelope() else {
            XCTFail()
            return
        }

        XCTAssertEqual(user.localID, 1)
        XCTAssertEqual(user.username, "test-username")
        XCTAssertEqual(user.firstName, "Test")
        XCTAssertEqual(user.lastName, "User")
        XCTAssertEqual(user.email, "example@example.blog")
        XCTAssertEqual(user.nickname, "User's Nickname")
        XCTAssertEqual(user.roles, ["administrator"])
        XCTAssertEqual(user.siteID, testSiteID)
    }
}

private extension UserMapperTests {
    func mapUserFromMockResponseWithDataEnvelope() async -> User? {
        // Note: the JSON content is shortened due to the "fields" parameter
        // usage in UserRemote.
        guard let response = Loader.contentsOf("user-complete") else {
            return nil
        }

        return try? await UserMapper(siteID: testSiteID).map(response: response)
    }

    func mapUserFromMockResponseWithoutDataEnvelope() async -> User? {
        // Note: the JSON content is shortened due to the "fields" parameter
        // usage in UserRemote.
        guard let response = Loader.contentsOf("user-complete-without-data") else {
            return nil
        }

        return try? await UserMapper(siteID: testSiteID).map(response: response)
    }
}
