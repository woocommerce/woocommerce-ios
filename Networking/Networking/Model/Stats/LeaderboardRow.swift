import Foundation

/// Represents a leaderboard item - Top Product
///
public struct LeaderboardRow: Decodable {

    enum CodingKeys: String, CodingKey {
        case subject
        case subjectValue
        case value
    }

    /// The subject of the leaderboard. - Could be: Product, Category, Customer, etc
    ///
    public let subject: LeaderboardRowContent<String>

    /// Value associated with the subject
    ///
    public let subjectValue: LeaderboardRowContent<Int>

    /// Value of te subject in the leaderboard
    ///
    public let value: LeaderboardRowContent<Double>
}
