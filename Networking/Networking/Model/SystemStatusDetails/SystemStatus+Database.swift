import Foundation

public extension SystemStatus {
    /// Subtype for details about database in system status.
    ///
    struct Database: Decodable {
        let wcDatabaseVersion: String
        let databasePrefix: String
        let databaseTables: DatabaseTables
        let databaseSize: DatabaseSize

        enum CodingKeys: String, CodingKey {
            case wcDatabaseVersion = "wc_database_version"
            case databasePrefix = "database_prefix"
            case databaseTables = "database_tables"
            case databaseSize = "database_size"
        }
    }

    /// Subtype for details about database size in system status.
    ///
    struct DatabaseSize: Decodable {
        let data: Double
        let index: Double
    }

    /// Subtype for details about database tables in system status.
    ///
    struct DatabaseTables: Decodable {
        let woocommerce: [String: [String: String]]
        let other: [String: [String: String]]
    }
}
