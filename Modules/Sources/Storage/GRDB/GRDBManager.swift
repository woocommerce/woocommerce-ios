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
                t.primaryKey("id", .text)
                t.column("siteID", .integer)
                t.column("productID", .integer)
                t.column("name", .text)
                t.column("productType", .text)
                t.column("sku", .text)
                t.column("globalUniqueID", .text)
                t.column("price", .text)
                t.column("regularPrice", .text)
                t.column("salePrice", .text)
                t.column("onSale", .boolean)
                t.column("downloadable", .boolean)
            }
        }

        try migrator.migrate(databaseQueue)
    }
}
