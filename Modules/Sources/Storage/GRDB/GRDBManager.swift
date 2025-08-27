import Foundation
import GRDB

public final class GRDBManager {

    let databaseQueue: DatabaseQueue
    private let databasePath: String

    public init(databasePath: String) throws {
        self.databasePath = databasePath

        let databaseURL = URL(fileURLWithPath: databasePath)
        let directoryURL = databaseURL.deletingLastPathComponent()

        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)

        self.databaseQueue = try DatabaseQueue(path: databasePath)

        try migrateIfNeeded()
    }

    init() throws {
        self.databasePath = "in-memory"
        self.databaseQueue = try DatabaseQueue()
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

        try migrator.migrate(databaseQueue)
    }
}
