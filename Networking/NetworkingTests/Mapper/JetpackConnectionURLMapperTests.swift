import XCTest
@testable import Networking

/// JetpackConnectionURLMapper Unit Tests
///
final class JetpackConnectionURLMapperTests: XCTestCase {

    func test_url_is_properly_parsed() async {
        guard let url = await mapURLFromMockResponse() else {
            XCTFail()
            return
        }
        let expectedURL = "https://jetpack.wordpress.com/jetpack.authorize/1/?response_type=code&client_id=2099457"
        assertEqual(url.absoluteString, expectedURL)
    }
}

private extension JetpackConnectionURLMapperTests {
    func mapURLFromMockResponse() async -> URL? {
        guard let response = Loader.contentsOf("jetpack-connection-url") else {
            return nil
        }

        return try? await JetpackConnectionURLMapper().map(response: response)
    }
}
