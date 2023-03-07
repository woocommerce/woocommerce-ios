import Foundation

public extension SystemStatus {
    /// Subtype for details about database in system status.
    ///
    struct Database: Decodable {
        public let wcDatabaseVersion: String
        public let databasePrefix: String
        public let databaseTables: DatabaseTables
        public let databaseSize: DatabaseSize

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
        public let data: Double
        public let index: Double
    }

    /// Subtype for details about database tables in system status.
    ///
    struct DatabaseTables: Decodable {
        public let woocommerce: [String: DatabaseTable]
        public let other: [String: DatabaseTable]
    }

    /// Subtype for details about a database table.
    ///
    struct DatabaseTable: Decodable {
        public let data: String
        public let index: String
        public let engine: String
    }
}
