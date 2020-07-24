import Foundation

/// Represents a leaderboard item - Top Product
///
public struct LeaderboardRow: Decodable {

    enum CodingKeys: String, CodingKey {
        case subject
        case quantity
        case total
    }

    /// The subject of the leaderboard. - Could be: Product, Category, Customer, etc
    ///
    public let subject: LeaderboardRowContent<String>

    /// Quantity associated with the subject in the leaderboard
    ///
    public let quantity: LeaderboardRowContent<Int>

    /// Total ranking of the subject in the leaderboard
    ///
    public let total: LeaderboardRowContent<Double>

    public init(subject: LeaderboardRowContent<String>, quantity: LeaderboardRowContent<Int>, total: LeaderboardRowContent<Double>) {
        self.subject = subject
        self.quantity = quantity
        self.total = total
    }
}
