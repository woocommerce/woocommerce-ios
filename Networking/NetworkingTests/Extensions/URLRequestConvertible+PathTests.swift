import XCTest
@testable import Networking

final class URLRequestConvertible_PathTests: XCTestCase {
    private let network = MockNetwork()

    override func setUp() {
        super.setUp()
        network.removeAllSimulatedResponses()
    }

    // MARK: - `pathForAnalytics`

    // Example from `ProductsRemote.loadAllProducts`.
    func test_pathForAnalytics_returns_path_of_JetpackRequest() throws {
        // Given
        let productsRemote = ProductsRemote(network: network)
        productsRemote.loadAllProducts(for: 134, completion: { _ in })

        // When
        let request = try XCTUnwrap(network.requestsForResponseData.first)

        // Then
        XCTAssertEqual(request.pathForAnalytics, "products")
        XCTAssertTrue(request is JetpackRequest)
    }

    // Example from `AccountRemote.loadSites`.
    func test_pathForAnalytics_returns_path_of_DotcomRequest() throws {
        // Given
        let productsRemote = AccountRemote(network: network)
        _ = productsRemote.loadSites()

        // When
        let request = try XCTUnwrap(network.requestsForResponseData.first)

        // Then
        XCTAssertEqual(request.pathForAnalytics, "me/sites")
        XCTAssertTrue(request is DotcomRequest)
    }

    func test_pathForAnalytics_returns_nil_when_request_is_not_supported() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://public-api.wordpress.com/rest/v1.1/jetpack-blogs/6/rest-api/?json=true"))

        // When
        let request = URLRequest(url: url)

        // Then
        XCTAssertNil(request.pathForAnalytics)
    }
}
