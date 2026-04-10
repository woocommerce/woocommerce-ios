import Foundation
import GRDB

public protocol GRDBManagerProtocol {
    var databaseConnection: GRDBDatabaseConnection { get }
    func reset() throws
}

public protocol GRDBDatabaseConnection: DatabaseReader & DatabaseWriter {}

public final class GRDBManager: GRDBManagerProtocol {

    public let databaseConnection: GRDBDatabaseConnection

    public init(databasePath: String) throws {
        let databaseURL = URL(fileURLWithPath: databasePath)
        let directoryURL = databaseURL.deletingLastPathComponent()

        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)

        self.databaseConnection = try DatabaseQueue(path: databasePath)

        try migrateIfNeeded()
    }

    // Creates an in-memory database, intended for use in tests.
    init() throws {
        self.databaseConnection = try DatabaseQueue()
        try migrateIfNeeded()
    }

    /// Resets the database by deleting all data from all tables
    /// Used when user logs out to ensure no data leaks between sessions
    public func reset() throws {
        try databaseConnection.write { db in
            // Disable foreign key constraints temporarily to avoid dependency issues
            try db.execute(sql: "PRAGMA foreign_keys = OFF")

            // Get all user tables (excluding sqlite internal tables and FTS5 shadow tables)
            // FTS5 shadow tables have suffixes: _data, _idx, _content, _docsize, _config
            let tableNames = try String.fetchAll(db, sql: """
                SELECT name FROM sqlite_master
                WHERE type = 'table'
                AND name NOT LIKE 'sqlite_%'
                AND name NOT LIKE 'grdb_%'
                AND name NOT LIKE '%_data'
                AND name NOT LIKE '%_idx'
                AND name NOT LIKE '%_content'
                AND name NOT LIKE '%_docsize'
                AND name NOT LIKE '%_config'
            """)

            // Delete all data from each table
            for tableName in tableNames {
                try db.execute(sql: "DELETE FROM \(tableName)")
            }

            // Clear FTS virtual tables separately (this handles their shadow tables automatically)
            // FTS5 virtual tables are listed as 'table' type but deleting from them clears shadow tables
            let ftsTableNames = try String.fetchAll(db, sql: """
                SELECT name FROM sqlite_master
                WHERE type = 'table'
                AND sql LIKE '%USING fts5%'
            """)

            for ftsTableName in ftsTableNames {
                try db.execute(sql: "DELETE FROM \(ftsTableName)")
            }

            // Re-enable foreign key constraints
            try db.execute(sql: "PRAGMA foreign_keys = ON")
        }
    }
}

private extension GRDBManager {
    func migrateIfNeeded() throws {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("V001InitialSchema") { db in
            try V001InitialSchema.migrate(db)
        }

        migrator.registerMigration("V002FTSSearch") { db in
            try V002FTSSearch.migrate(db)
        }

        try migrator.migrate(databaseConnection)
    }
}

extension DatabaseQueue: GRDBDatabaseConnection {}
