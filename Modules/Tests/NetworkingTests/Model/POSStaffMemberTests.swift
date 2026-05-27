import XCTest
@testable import Networking

final class POSStaffMemberTests: XCTestCase {
    func test_decode_when_full_record_then_parses_fields() throws {
        // Given
        let json = """
        {
          "user_id": 42,
          "user_login": "mike",
          "display_name": "Mike",
          "role": "pos_cashier",
          "capabilities": { "view_pos": true, "read": true },
          "pin": {
            "algo": "pbkdf2-sha256",
            "iterations": 10000,
            "salt": "c2FsdA==",
            "hash": "aGFzaA=="
          }
        }
        """.data(using: .utf8)!

        // When
        let sut = try JSONDecoder().decode(POSStaffMember.self, from: json)

        // Then
        XCTAssertEqual(sut.userID, 42)
        XCTAssertEqual(sut.userLogin, "mike")
        XCTAssertEqual(sut.displayName, "Mike")
        XCTAssertEqual(sut.role, "pos_cashier")
        XCTAssertEqual(sut.capabilities, ["view_pos": true, "read": true])
        XCTAssertEqual(sut.pin?.algo, "pbkdf2-sha256")
        XCTAssertEqual(sut.pin?.iterations, 10000)
        XCTAssertEqual(sut.pin?.salt, "c2FsdA==")
        XCTAssertEqual(sut.pin?.hash, "aGFzaA==")
    }

    func test_decode_when_pin_is_null_then_pin_is_nil() throws {
        // Given
        let json = """
        {
          "user_id": 1, "user_login": "admin", "display_name": "Admin",
          "role": "administrator", "capabilities": {}, "pin": null
        }
        """.data(using: .utf8)!

        // When
        let sut = try JSONDecoder().decode(POSStaffMember.self, from: json)

        // Then
        XCTAssertNil(sut.pin)
    }
}
