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

            // Get all user tables (excluding sqlite internal tables)
            let tableNames = try String.fetchAll(db, sql: """
                SELECT name FROM sqlite_master
                WHERE type = 'table'
                AND name NOT LIKE 'sqlite_%'
                AND name NOT LIKE 'grdb_%'
            """)

            // Delete all data from each table
            for tableName in tableNames {
                try db.execute(sql: "DELETE FROM \(tableName)")
            }

            // Re-enable foreign key constraints
            try db.execute(sql: "PRAGMA foreign_keys = ON")
        }
    }
}

private extension GRDBManager {
    func migrateIfNeeded() throws {
        var migrator = DatabaseMigrator()

        #if DEBUG
        // Speed up development by dropping the database when migrations change
        migrator.eraseDatabaseOnSchemaChange = true
        #endif

        migrator.registerMigration("V001InitialSchema") { db in
            try V001InitialSchema.migrate(db)
        }

        try migrator.migrate(databaseConnection)
    }
}

extension DatabaseQueue: GRDBDatabaseConnection {}
