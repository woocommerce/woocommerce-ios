import XCTest
@testable import Networking


/// NoteHashListMapperTests Unit Tests
///
class NoteHashListMapperTests: XCTestCase {

    /// Verifies that the Broken Response causes the mapper to throw an error.
    ///
    func test_broken_response_forces_mapper_to_throw_an_error() {
        XCTAssertThrowsError(try mapLoadBrokenResponse())
    }

    /// Verifies that a proper response is properly parsed (YAY!).
    ///
    func test_sample_hashes_are_properly_loaded() {
        let hashes = try? mapLoadAllHashesResponse()

        XCTAssertNotNil(hashes)
        XCTAssertEqual(hashes?.count, 40)
    }

    /// Verifies that a sample NoteHash entity is properly deserialized.
    ///
    func test_NoteHash_entity_is_properly_parsed() {
        let hashes = try? mapLoadAllHashesResponse()
        let hashZero = hashes![0]

        XCTAssertEqual(hashZero.noteID, 3606596126)
        XCTAssertEqual(hashZero.hash, 3018427640)
    }
}


/// Private Methods.
///
private extension NoteHashListMapperTests {

    /// Returns the NoteHashListMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapNoteHashes(from filename: String) throws -> [NoteHash] {
        let response = Loader.contentsOf(filename)!
        let mapper = NoteHashListMapper()

        return try mapper.map(response: response)
    }

    /// Returns the NoteHashListMapper output upon receiving `notifications` endpoint's response.
    ///
    func mapLoadAllHashesResponse() throws -> [NoteHash] {
        return try mapNoteHashes(from: "notifications-load-hashes")
    }

    /// Returns the NoteHashListMapper output upon receiving a broken response.
    ///
    func mapLoadBrokenResponse() throws -> [NoteHash] {
        return try mapNoteHashes(from: "generic_error")
    }
}
