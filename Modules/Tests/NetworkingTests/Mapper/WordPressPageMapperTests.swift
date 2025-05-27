import XCTest
@testable import Networking

final class WordPressPageMapperTests: XCTestCase {

    func test_response_is_properly_parsed() throws {
        let list = mapWordPressPageListResponse()
        XCTAssertEqual(list, [
            .init(id: 21, title: "Cart", link: "https://example.com/cart/"),
            .init(id: 20, title: "Shop", link: "https://example.com/shop/"),
            .init(id: 6, title: "Blog", link: "https://example.com/blog/")
        ])
    }

}

private extension WordPressPageMapperTests {
    /// Returns the WordPressPageListMapper output upon receiving success response
    ///
    func mapWordPressPageListResponse() -> [WordPressPage] {
        guard let response = Loader.contentsOf("wp-page-list-success") else {
            return []
        }
        return (try? WordPressPageListMapper().map(response: response)) ?? []
    }
}
