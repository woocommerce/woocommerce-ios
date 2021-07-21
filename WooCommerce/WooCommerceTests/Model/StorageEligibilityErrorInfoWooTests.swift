import XCTest
import Yosemite

@testable import WooCommerce

final class StorageEligibilityErrorInfoWooTests: XCTestCase {
    func test_errorInfo_humanizedRoles_with_multipleRoles_returns_correct_format() {
        // Given
        let errorInfo = StorageEligibilityErrorInfo(name: "", roles: ["author", "editor"])

        // When
        let rolesText = errorInfo.humanizedRoles

        // Then
        XCTAssertEqual(rolesText, "Author, Editor")
    }

    func test_errorInfo_humanizedRoles_with_multipleRoles_containingSnakeCase_returns_correct_format() {
        // Given
        let errorInfo = StorageEligibilityErrorInfo(name: "", roles: ["shop_manager", "administrator"])

        // When
        let rolesText = errorInfo.humanizedRoles

        // Then
        XCTAssertEqual(rolesText, "Shop Manager, Administrator")
    }
}
