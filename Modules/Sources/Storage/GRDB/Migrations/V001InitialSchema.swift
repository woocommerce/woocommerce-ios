import Foundation
import GRDB

struct V001InitialSchema {
    static func migrate(_ db: Database) throws {
        try createProductTable(db)
    }

    static func createProductTable(_ db: Database) throws {
        // Note that it's best to use strings for names in the database
        // not derive them from a Swift class.
        // https://swiftpackageindex.com/groue/grdb.swift/v7.6.1/documentation/grdb/migrations#Good-Practices-for-Defining-Migrations
        try db.create(table: "posProduct") { productTable in
            productTable.primaryKey(["siteID", "productID"])

            productTable.column("siteID", .integer).notNull()
            productTable.column("productID", .integer).notNull()
            productTable.column("name", .text).notNull()
            productTable.column("productTypeKey", .text).notNull()

            productTable.column("fullDescription", .text)
            productTable.column("shortDescription", .text)

            productTable.column("sku", .text)
            productTable.column("globalUniqueID", .text)
            productTable.column("price", .text).notNull()

            productTable.column("downloadable", .boolean).notNull()

            productTable.column("parentID", .integer).notNull()
        }
    }
}
