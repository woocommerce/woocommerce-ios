import XCTest
@testable import Networking
@testable import NetworkingCore

final class POSStaffMapperTests: XCTestCase {
    func test_map_when_envelope_with_three_staff_then_returns_three_members() throws {
        // Given
        let response = Loader.contentsOf("pos-staff-list")!

        // When
        let staff = try POSStaffMapper().map(response: response)

        // Then
        XCTAssertEqual(staff.count, 3)
        XCTAssertEqual(staff[0].userID, 1)
        XCTAssertEqual(staff[1].userID, 7)
        XCTAssertEqual(staff[2].userID, 42)
        XCTAssertNotNil(staff[0].pin)
        XCTAssertNotNil(staff[1].pin)
        XCTAssertNil(staff[2].pin)
    }

    func test_map_when_empty_envelope_then_returns_empty() throws {
        // Given
        let response = #"{"staff":[]}"#.data(using: .utf8)!

        // When
        let staff = try POSStaffMapper().map(response: response)

        // Then
        XCTAssertEqual(staff.count, 0)
    }

    func test_map_when_response_missing_staff_key_then_throws() {
        // Given
        let response = #"{"items":[]}"#.data(using: .utf8)!

        // When / Then
        XCTAssertThrowsError(try POSStaffMapper().map(response: response))
    }
}
