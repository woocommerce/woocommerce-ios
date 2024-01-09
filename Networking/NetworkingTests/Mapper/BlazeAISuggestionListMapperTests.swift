import XCTest
@testable import Networking

final class BlazeAISuggestionListMapperTests: XCTestCase {
    func test_it_parses_all_contents_in_response() throws {
        // When
        let list = try XCTUnwrap(mapLoadBlazeAISuggestionListResponse())

        // Then
        XCTAssertEqual(list, [
            .init(siteName: "Classic Fridge!",
                  textSnippet: "Apartment Sized 7.5 cu. ft. Two Door Refrigerator with Retro Design and Low Energy Consumption. Click for more!"),
            .init(siteName: "Funky Retro Fridge",
                  textSnippet: "Epic Black Retro Refrigerator with Chrome handles, low energy consumption and lots of door storage. Buy now!"),
            .init(siteName: "Cool Vintage Refrigerator",
                  textSnippet: "Automatic Defrost, Low Energy Consumption, 2L bottle Storage, 1 Year Warranty. Check it out!")
        ])
    }
}

private extension BlazeAISuggestionListMapperTests {

    /// Returns the `BlazeAISuggestionListMapper` output upon receiving `filename` (Data Encoded)
    ///
    func mapBlazeAISuggestionList(from filename: String) throws -> [BlazeAISuggestion] {
        guard let response = Loader.contentsOf(filename) else {
            throw FileNotFoundError()
        }

        return try BlazeAISuggestionListMapper().map(response: response)
    }

    /// Returns the `BlazeAISuggestionListMapper` output from `blaze-ai-suggestions.json`
    ///
    func mapLoadBlazeAISuggestionListResponse() throws -> [BlazeAISuggestion] {
        try mapBlazeAISuggestionList(from: "blaze-ai-suggestions")
    }

    struct FileNotFoundError: Error {}
}
