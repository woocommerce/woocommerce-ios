import XCTest
@testable import WooCommerce

final class CaseIterable_HelpersTests: XCTestCase {
    func test_it_returns_next_case_when_available() {
        // Given
        let sut = TestEnum.first

        // Then
        XCTAssertEqual(sut.next(), TestEnum.last)
    }

    func test_it_returns_nil_if_self_is_last_case() {
        // Given
        let sut = TestEnum.last

        // Then
        XCTAssertNil(sut.next())
    }
}

private enum TestEnum: CaseIterable {
    case first
    case last
}
