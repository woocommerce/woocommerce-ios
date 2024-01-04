import XCTest
@testable import Networking

final class BlazeImpressionsMapperTests: XCTestCase {

    /// Verifies that the response is parsed
    ///
    func test_BlazeImpressionsMapper_parses_all_contents_in_response() throws {
        let blazeImpressions = try mapLoadBlazeImpressionsResponse()

        XCTAssertEqual(blazeImpressions.totalImpressionsMax, 24200)
        XCTAssertEqual(blazeImpressions.totalImpressionsMin, 17900)
    }
}

// MARK: - Test Helpers
//
private extension BlazeImpressionsMapperTests {

    /// Returns the BlazeImpressionsMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapBlazeImpressions(from filename: String) throws -> BlazeImpressions {
        guard let response = Loader.contentsOf(filename) else {
            throw FileNotFoundError()
        }

        return try BlazeImpressionsMapper().map(response: response)
    }

    /// Returns the BlazeImpressionsMapper output from `blaze-impressions.json`
    ///
    func mapLoadBlazeImpressionsResponse() throws -> BlazeImpressions {
        return try mapBlazeImpressions(from: "blaze-impressions")
    }

    struct FileNotFoundError: Error {}
}
