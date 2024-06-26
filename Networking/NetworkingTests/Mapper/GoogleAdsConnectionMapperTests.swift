import XCTest
@testable import Networking

final class GoogleAdsConnectionMapperTests: XCTestCase {

    func test_google_ads_connection_is_properly_parsed_with_data_envelope() throws {
        // When
        let connection = try mapGoogleAdsConnection(from: "gla-connection-with-data-envelope")

        // Then
        XCTAssertEqual(connection?.id, 3904318964)
        XCTAssertEqual(connection?.currency, "USD")
        XCTAssertEqual(connection?.symbol, "$")
        XCTAssertEqual(connection?.rawStatus, "incomplete")
        XCTAssertEqual(connection?.status, .incomplete)
    }

    func test_google_ads_connection_is_properly_parsed_without_data_envelope() throws {
        // When
        let connection = try mapGoogleAdsConnection(from: "gla-connection-without-data-envelope")

        // Then
        XCTAssertEqual(connection?.id, 1234567890)
        XCTAssertEqual(connection?.currency, "USD")
        XCTAssertEqual(connection?.symbol, "$")
        XCTAssertEqual(connection?.rawStatus, "connected")
        XCTAssertEqual(connection?.status, .connected)
    }
}

private extension GoogleAdsConnectionMapperTests {
    /// Returns the GoogleAdsConnection output upon receiving `filename` (Data Encoded)
    ///
    func mapGoogleAdsConnection(from filename: String) throws -> GoogleAdsConnection? {
        guard let response = Loader.contentsOf(filename) else {
            return nil
        }

        return try GoogleAdsConnectionMapper().map(response: response)
    }
}
