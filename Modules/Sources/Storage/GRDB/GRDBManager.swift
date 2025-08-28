import Foundation
import GRDB

public protocol GRDBManagerProtocol {
    var databaseConnection: GRDBDatabaseConnection { get }
}

public protocol GRDBDatabaseConnection: DatabaseReader & DatabaseWriter {}

public final class GRDBManager: GRDBManagerProtocol {

    public var databaseConnection: GRDBDatabaseConnection

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
