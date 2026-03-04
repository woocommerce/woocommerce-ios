import XCTest
@testable import Networking
@testable import NetworkingCore

final class WordPressMediaMapperTests: XCTestCase {

    /// Tests that WordPressMediaList and consequently WordPressMedia is correctly mapped from a response where sizes is a dictionary.
    ///
    /// - Throws: An error if the mapping fails.
    func test_it_maps_WordPressMediaList_correctly_with_sizes_as_dictionary() throws {
        // Given
        let data = try retrieveWordPressMediaResponseWithSizesAsDictionary()
        let mapper = WordPressMediaListMapper()

        // When
        let mediaList = try mapper.map(response: data)

        // Then
        XCTAssertEqual(mediaList.count, 3)
        let media = mediaList.first { $0.mediaID == 22 }
        XCTAssertNotNil(media)
        XCTAssertEqual(media?.details?.sizes?["medium"]?.width, 300)
        XCTAssertEqual(media?.details?.sizes?["medium"]?.height, 225)
        XCTAssertEqual(media?.details?.sizes?["large"]?.width, 1024)
        XCTAssertEqual(media?.details?.sizes?["large"]?.height, 768)
    }

    /// Tests that WordPressMediaList and consequently WordPressMedia is correctly mapped from a response where media_details is an array.
    ///
    /// - Throws: An error if the mapping fails.
    func test_it_maps_WordPressMediaList_correctly_with_media_details_as_array() throws {
        // Given
        let data = try retrieveWordPressMediaResponseWithMediaDetailsAsArray()
        let mapper = WordPressMediaListMapper()

        // When
        let mediaList = try mapper.map(response: data)

        // Then
        XCTAssertEqual(mediaList.count, 1)
        let media = mediaList.first { $0.mediaID == 7 }
        XCTAssertNotNil(media)
        XCTAssertNil(media?.details)
    }

    /// Tests that WordPressMediaList and consequently WordPressMedia is correctly mapped from a response where sizes is an empty array.
    ///
    /// - Throws: An error if the mapping fails.
    func test_it_maps_WordPressMediaList_correctly_with_sizes_as_empty_array() throws {
        // Given
        let data = try retrieveWordPressMediaResponseWithSizesAsEmptyArray()
        let mapper = WordPressMediaListMapper()

        // When
        let mediaList = try mapper.map(response: data)

        // Then
        XCTAssertEqual(mediaList.count, 2)
        let media = mediaList.first { $0.mediaID == 13 }
        XCTAssertNotNil(media)
        XCTAssertNil(media?.details?.sizes)
    }
}

// MARK: - Test Helpers
///
private extension WordPressMediaMapperTests {
    func retrieveWordPressMediaResponseWithSizesAsDictionary() throws -> Data {
        guard let response = Loader.contentsOf("media-library") else {
            throw FileNotFoundError()
        }

        return response
    }

    func retrieveWordPressMediaResponseWithMediaDetailsAsArray() throws -> Data {
        guard let response = Loader.contentsOf("media-library-with-media-details-as-array") else {
            throw FileNotFoundError()
        }

        return response
    }

    func retrieveWordPressMediaResponseWithSizesAsEmptyArray() throws -> Data {
        guard let response = Loader.contentsOf("media-library-with-empty-sizes") else {
            throw FileNotFoundError()
        }

        return response
    }

    struct FileNotFoundError: Error {}
}
