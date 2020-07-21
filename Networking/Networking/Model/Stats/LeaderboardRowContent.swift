import Foundation

/// Generic tyoe that represents the HTML and raw content of a leaderboard item values
///
public struct LeaderboardRowContent<Type: Decodable>: Decodable {

    /// HTML content
    ///
    public let display: String

    /// Raw value
    ///
    public let value: Type
}
