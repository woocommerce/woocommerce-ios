import XCTest

@testable import WooCommerce

final class EligibilityErrorInfoTests: XCTestCase {

    func test_errorInfo_init_with_correct_dictionary_correctly_creates_object() {
        // Given
        let dictionary: [String: String] = ["name": "Person", "roles": "author,editor"]

        // When
        let errorInfo = EligibilityErrorInfo(from: dictionary)

        // Then
        XCTAssertNotNil(errorInfo)
        XCTAssertEqual(errorInfo?.name, "Person")
        XCTAssertEqual(errorInfo?.roles, ["author", "editor"])
    }

    func test_errorInfo_init_with_wrong_dictionary_returns_nil() {
        // Given
        let dictionary: [String: String] = ["foo": "Person", "bar": "author,editor"]

        // When
        let errorInfo = EligibilityErrorInfo(from: dictionary)

        // Then
        XCTAssertNil(errorInfo)
    }

    func test_errorInfo_toDictionary_returns_dictionary_with_correct_format() {
        // Given
        let errorInfo = EligibilityErrorInfo(name: "Person", roles: ["author", "editor"])

        // When
        let dictionary = errorInfo.toDictionary()

        // Then
        XCTAssertEqual(dictionary, ["name": "Person", "roles": "author,editor"])
    }

    func test_errorInfo_humanizedRoles_with_multipleRoles_returns_correct_format() {
        // Given
        let errorInfo = EligibilityErrorInfo(name: "", roles: ["author", "editor"])

        // When
        let rolesText = errorInfo.humanizedRoles

        // Then
        XCTAssertEqual(rolesText, "Author, Editor")
    }

    func test_errorInfo_humanizedRoles_with_multipleRoles_containingSnakeCase_returns_correct_format() {
        // Given
        let errorInfo = EligibilityErrorInfo(name: "", roles: ["shop_manager", "administrator"])

        // When
        let rolesText = errorInfo.humanizedRoles

        // Then
        XCTAssertEqual(rolesText, "Shop Manager, Administrator")
    }
}
