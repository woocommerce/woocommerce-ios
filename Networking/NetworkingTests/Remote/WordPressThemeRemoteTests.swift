import XCTest
@testable import Networking

final class WordPressThemeRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    private var network: MockNetwork!

    override func setUp() {
        super.setUp()
        network = MockNetwork()
    }

    override func tearDown() {
        network = nil
        super.tearDown()
    }

    // MARK: - loadSuggestedThemes tests

    func test_loadSuggestedThemes_returns_parsed_campaigns() async throws {
        // Given
        let remote = WordPressThemeRemote(network: network)

        let suffix = "themes?filter=subject:store&number=100"
        network.simulateResponse(requestUrlSuffix: suffix, filename: "theme-list-success")

        // When
        let results = try await remote.loadSuggestedThemes()

        // Then
        XCTAssertEqual(results.count, 1)
        let item = try XCTUnwrap(results.first)
        XCTAssertEqual(item.id, "tsubaki")
        XCTAssertEqual(item.name, "Tsubaki")
        // swiftlint:disable:next line_length
        XCTAssertEqual(item.description, "Tsubaki puts the spotlight on your products and your customers.  This theme leverages WooCommerce to provide you with intuitive product navigation and the patterns you need to master digital merchandising.")
        XCTAssertEqual(item.demoURI, "https://tsubakidemo.wpcomstaging.com/")
    }

    func test_loadSuggestedThemes_properly_relays_networking_errors() async {
        // Given
        let remote = WordPressThemeRemote(network: network)

        let expectedError = NetworkError.unacceptableStatusCode(statusCode: 403)
        let suffix = "themes?filter=subject:store&number=100"
        network.simulateError(requestUrlSuffix: suffix, error: expectedError)

        do {
            // When
            _ = try await remote.loadSuggestedThemes()

            // Then
            XCTFail("Request should fail")
        } catch {
            // Then
            XCTAssertEqual(error as? NetworkError, expectedError)
        }
    }
}
