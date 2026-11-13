import XCTest
@testable import Networking
@testable import NetworkingCore


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
        XCTAssertEqual(account.crashReportingOptOut, false)
        XCTAssertEqual(account.firstName, "Dem 123")
        XCTAssertEqual(account.lastName, "Nines")
    }

    /// Verifies that a `null` crash reporting opt out is parsed as `nil`, so it can be told apart from an explicit choice.
    ///
    func test_crashReportingOptOut_when_null_then_parses_as_nil() throws {
        // Given
        let response = Data(#"{"tracks_opt_out": false, "woomobile_crash_reporting_opt_out": null}"#.utf8)

        // When
        let account = try AccountSettingsMapper(userID: 10).map(response: response)

        // Then
        XCTAssertNil(account.crashReportingOptOut)
    }

    /// Verifies that a missing crash reporting opt out is parsed as `nil`, so it can be told apart from an explicit choice.
    ///
    func test_crashReportingOptOut_when_missing_then_parses_as_nil() throws {
        // Given
        let response = Data(#"{"tracks_opt_out": false}"#.utf8)

        // When
        let account = try AccountSettingsMapper(userID: 10).map(response: response)

        // Then
        XCTAssertNil(account.crashReportingOptOut)
    }

    /// Verifies that an explicit crash reporting opt out is parsed as a boolean.
    ///
    func test_crashReportingOptOut_when_true_then_parses_as_true() throws {
        // Given
        let response = Data(#"{"tracks_opt_out": false, "woomobile_crash_reporting_opt_out": true}"#.utf8)

        // When
        let account = try AccountSettingsMapper(userID: 10).map(response: response)

        // Then
        XCTAssertEqual(account.crashReportingOptOut, true)
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
