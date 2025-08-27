import Foundation
import GRDB

public final class GRDBManager {

    private let databaseQueue: DatabaseQueue
    private let databasePath: String

    public init(databasePath: String) throws {
        self.databasePath = databasePath

        let databaseURL = URL(fileURLWithPath: databasePath)
        let directoryURL = databaseURL.deletingLastPathComponent()

        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)

        self.databaseQueue = try DatabaseQueue(path: databasePath)

        try migrateIfNeeded()
    }
    
}

private extension GRDBManager {
    func migrateIfNeeded() throws {
        var migrator = DatabaseMigrator()

        #if DEBUG
        // Speed up development by nuking the database when migrations change
        migrator.eraseDatabaseOnSchemaChange = true
        #endif

        // 1st migration

        // Note that it's best to use strings for names in the database
        // not derive them from a Swift class.
        // https://swiftpackageindex.com/groue/grdb.swift/v7.6.1/documentation/grdb/migrations#Good-Practices-for-Defining-Migrations
        migrator.registerMigration("Create posProduct table") { db in
            try db.create(table: "posProduct") { t in
                t.primaryKey(["siteID", "productID"])

                t.column("siteID", .integer).notNull()
                t.column("productID", .integer).notNull()
                t.column("name", .text).notNull()
                t.column("productTypeKey", .text).notNull()

                t.column("fullDescription", .text)
                t.column("shortDescription", .text)

                t.column("sku", .text)
                t.column("globalUniqueID", .text)
                t.column("price", .text).notNull()

                t.column("downloadable", .boolean).notNull()

                t.column("parentID", .integer).notNull()
            }
        }

        try migrator.migrate(databaseQueue)
    }
}
