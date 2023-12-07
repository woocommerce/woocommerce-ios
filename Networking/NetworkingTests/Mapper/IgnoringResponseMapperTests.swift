import XCTest
@testable import Networking


/// IgnoringResponseMapper Unit Tests
///
class IgnoringResponseMapperTests: XCTestCase {

    func test_null_data_does_not_error() async throws {
        try await mapData(from: "null-data")
    }

    func test_non_null_data_does_not_error() async throws {
        try await mapData(from: "generic_success_data")
    }

    func test_missing_data_envelope_does_not_error() async throws {
        try await mapData(from: "generic_success")
    }
}

private extension IgnoringResponseMapperTests {

    /// Runs EmptyResponseMapper on encoded data in `filename`
    ///
    func mapData(from filename: String) async throws {
        guard let response = Loader.contentsOf(filename) else {
            throw IgnoringResponseMapperTestsError.noFileFound
        }

        try await IgnoringResponseMapper().map(response: response)
    }

    enum IgnoringResponseMapperTestsError: Error {
        case noFileFound
    }
}
