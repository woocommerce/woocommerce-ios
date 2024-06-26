import XCTest
@testable import Networking

final class JetpackAIQueryResponseMapperTests: XCTestCase {
    func test_it_parses_all_contents_in_response() throws {
        // When
        let response = try XCTUnwrap(mapLoadJetpackAIQueryResponse())

        // Then
        XCTAssertEqual(response, "The Wapuu Pencil is a perfect writing tool for those who love cute things.")
    }
}

private extension JetpackAIQueryResponseMapperTests {
    /// Returns the `JetpackAIQueryResponseMapper` output upon receiving `filename` (Data Encoded)
    ///
    func mapJetpackAIQueryResponse(from filename: String) throws -> String {
        guard let response = Loader.contentsOf(filename) else {
            throw FileNotFoundError()
        }

        return try JetpackAIQueryResponseMapper().map(response: response)
    }

    /// Returns the `JetpackAIQueryResponseMapper` output from `generative-text-success.json`
    ///
    func mapLoadJetpackAIQueryResponse() throws -> String {
        try mapJetpackAIQueryResponse(from: "generative-text-success")
    }

    struct FileNotFoundError: Error {}
}
