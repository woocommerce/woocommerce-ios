import XCTest
@testable import Networking

/// WordPressAPIVersion Unit Tests
///
final class WordPressAPIVersionTests: XCTestCase {

    func test_isWPOrgEndpoint_is_true_for_WordPressOrg_endpoints() {
        // Given
        let sut = WordPressAPIVersion.wpMark2

        // Then
        XCTAssertTrue(sut.isWPOrgEndpoint)
    }

    func test_isWPOrgEndpoint_is_false_for_WordPressCom_endpoints() {
        // Given
        let apis = WordPressAPIVersion.allCases.filter({ $0 != .wpMark2 })

        // Then
        for sut in apis {
            XCTAssertFalse(sut.isWPOrgEndpoint)
        }
    }
}
