import Foundation

/// Mapper: Leaderboard List
///
struct LeaderboardListMapper: Mapper {

    /// (Attempts) to convert a dictionary into a Leaderboards entity.
    ///
    func map(response: Data) throws -> [Leaderboard] {
        let decoder = JSONDecoder()
        return try decoder.decode(LeaderboardsEnvelope.self, from: response).data
    }
}

/// LeaderboardEnvelope Disposable Entity
/// `Leaderboards` endpoint returns the requested stats in the `data` key.
///
private struct LeaderboardsEnvelope: Decodable {
    let data: [Leaderboard]
}
