import XCTest
@testable import Networking

final class LeaderboardListMapperTests: XCTestCase {

    /// Verifies that leaderboard list is parsed.
    ///
    func test_mapper_parses_leaderboard_list_in_response_with_data_envelope() throws {
        // Given
        let list = try mapLeaderboardListResponse()

        // Then
        XCTAssertFalse(list.isEmpty)
    }

    /// Verifies that the leaderboard list is parsed when the response has no data envelope.
    ///
    func test_mapper_parses_leaderboard_list_in_response_without_data_envelope() throws {
        // Given
        let list = try mapLeaderboardListResponseWithoutDataEnvelope()

        // Then
        XCTAssertFalse(list.isEmpty)
    }
}

// MARK: - Test Helpers
///
private extension LeaderboardListMapperTests {

    /// Returns the LeaderboardListMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapLeaderboardList(from filename: String) throws -> [Leaderboard] {
        guard let response = Loader.contentsOf(filename) else {
            throw FileNotFoundError()
        }

        return try LeaderboardListMapper().map(response: response)
    }

    /// Returns the LeaderboardListMapper output from `products.json`
    ///
    func mapLeaderboardListResponse() throws -> [Leaderboard] {
        return try mapLeaderboardList(from: "leaderboards-year")
    }

    /// Returns the LeaderboardListMapper output from `leaderboards-products-without-data.json`
    ///
    func mapLeaderboardListResponseWithoutDataEnvelope() throws -> [Leaderboard] {
        return try mapLeaderboardList(from: "leaderboards-year-without-data")
    }

    struct FileNotFoundError: Error {}
}
