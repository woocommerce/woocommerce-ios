import Foundation

/// Represents the store leaderboad - Top Products
///
public struct Leaderboard: Decodable {

    enum CodingKeys: String, CodingKey {
        case id
        case label
        case rows
    }

    /// ID of the leaderboard
    ///
    public let id: String

    /// Name of the leaderboard
    ///
    public let label: String

    /// Top performers of the leaderboard - Could be: Products, Categories, Customers, etc
    ///
    public let rows: [LeaderboardRow]

    /// Tries to decode a leaderboard by making asumptions on the API response. - https://github.com/woocommerce/woocommerce-admin/issues/4806
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.label = try container.decode(String.self, forKey: .label)

        // We assume that rows will always be of type `Array<Array<Dictionary<_,_>>>`
        // If not an encoding error will be thrown
        let rawRows = try container.decode([[[String: AnyCodable]]].self, forKey: .rows)

        // Try to convert the previous data structure(Array of array of dictionaries) into an array of `LeaderboardRow`
        // Converts:
        // [ [ { content1 }, { content2 }, { content3 }], [ { content1 }, { content2 }, { content3 } ] ]
        //
        // Into:
        // [ leaderboardRow, leaderboardRow ]
        //
        // By re-encoding the underlying json into:
        // [ mergeDic(content1, content2, content3), mergeDic(content1, content2, content3) ]
        //
        //
        self.rows = try rawRows.map { rawRow in

            // Assemble a compound dicionary that is accepted by `LeaderboardRow` from the raw leaderboard row.
            // It is guaranteed that the row will contain at least 3 elements.
            let rawDictionary = [
                LeaderboardRow.CodingKeys.subject.rawValue: rawRow[0],
                LeaderboardRow.CodingKeys.quantity.rawValue: rawRow[1],
                LeaderboardRow.CodingKeys.total.rawValue: rawRow[2],
            ]

            // Encode the compound dictionary and let Swift decode the `LeaderboardRow`
            let encodedData = try JSONEncoder().encode(rawDictionary)
            return try JSONDecoder().decode(LeaderboardRow.self, from: encodedData)
        }
    }

    public init(id: String, label: String, rows: [LeaderboardRow]) {
        self.id = id
        self.label = label
        self.rows = rows
    }
}
