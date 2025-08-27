import Foundation
import GRDB

struct V001InitialSchema {
    static func migrate(_ db: Database) throws {
        try createProductTable(db)
        try createProductAttributeTable(db)
        try createProductImageTable(db)
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

    private static func createProductAttributeTable(_ db: Database) throws {
        try db.create(table: "posProductAttribute") { productAttributeTable in
            productAttributeTable.primaryKey(["siteID", "attributeID"])

            productAttributeTable.column("siteID", .integer).notNull()
            productAttributeTable.column("attributeID", .integer).notNull()
            productAttributeTable.column("productID", .integer).notNull()

            productAttributeTable.column("name", .text).notNull()
            productAttributeTable.column("position", .integer).notNull()
            productAttributeTable.column("visible", .boolean).notNull()
            productAttributeTable.column("variation", .boolean).notNull()
            productAttributeTable.column("options", .jsonText).notNull()

            productAttributeTable.foreignKey(["siteID", "productID"], references: "posProduct")
        }
    }

    private static func createProductImageTable(_ db: Database) throws {
        try db.create(table: "posProductImage") { productImageTable in
            productImageTable.primaryKey(["siteID", "imageID"])

            productImageTable.column("siteID", .integer).notNull()
            productImageTable.column("imageID", .integer).notNull()
            productImageTable.column("productID", .integer).notNull()

            productImageTable.column("dateCreated", .datetime).notNull()
            productImageTable.column("dateModified", .datetime)

            productImageTable.column("src", .text).notNull()
            productImageTable.column("name", .text)
            productImageTable.column("alt", .text)

            productImageTable.foreignKey(["siteID", "productID"], references: "posProduct")
        }
    }
}
