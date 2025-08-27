import Foundation
import GRDB

struct V001InitialSchema {
    // This migration is under development and not released yet.
    // It's still open for modification, until we ship.
    // TODO: Mark this as final when we enable the pointOfSaleLocalCatalogi1 feature flag

    static func migrate(_ db: Database) throws {
        try createProductTable(db)
        try createProductAttributeTable(db)
        try createProductImageTable(db)
        try createProductVariationTable(db)
        try createProductVariationAttributeTable(db)
        try createProductVariationImageTable(db)
    }

    static func createProductTable(_ db: Database) throws {
        // Note that it's best to use strings for names in the database
        // not derive them from a Swift class.
        // https://swiftpackageindex.com/groue/grdb.swift/v7.6.1/documentation/grdb/migrations#Good-Practices-for-Defining-Migrations
        try db.create(table: "product") { productTable in
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
        try db.create(table: "productAttribute") { productAttributeTable in
            productAttributeTable.primaryKey(["siteID", "attributeID"])

            productAttributeTable.column("siteID", .integer).notNull()
            productAttributeTable.column("attributeID", .integer).notNull()
            productAttributeTable.column("productID", .integer).notNull()

            productAttributeTable.column("name", .text).notNull()
            productAttributeTable.column("position", .integer).notNull()
            productAttributeTable.column("visible", .boolean).notNull()
            productAttributeTable.column("variation", .boolean).notNull()
            productAttributeTable.column("options", .jsonText).notNull()

            productAttributeTable.foreignKey(["siteID", "productID"], references: "product")
        }
    }

    private static func createProductImageTable(_ db: Database) throws {
        try db.create(table: "productImage") { productImageTable in
            productImageTable.primaryKey(["siteID", "imageID"])

            productImageTable.column("siteID", .integer).notNull()
            productImageTable.column("imageID", .integer).notNull()
            productImageTable.column("productID", .integer).notNull()

            productImageTable.column("dateCreated", .datetime).notNull()
            productImageTable.column("dateModified", .datetime)

            productImageTable.column("src", .text).notNull()
            productImageTable.column("name", .text)
            productImageTable.column("alt", .text)

            productImageTable.foreignKey(["siteID", "productID"], references: "product")
        }
    }

    private static func createProductVariationTable(_ db: Database) throws {
        try db.create(table: "productVariation") { productVariationTable in
            productVariationTable.primaryKey(["siteID", "productVariationID"])

            productVariationTable.column("siteID", .integer).notNull()
            productVariationTable.column("productVariationID", .integer).notNull()
            productVariationTable.column("productID", .integer).notNull()

            productVariationTable.column("sku", .text)
            productVariationTable.column("globalUniqueID", .text)
            productVariationTable.column("price", .text).notNull()

            productVariationTable.column("downloadable", .boolean).notNull()

            productVariationTable.column("description", .text)

            productVariationTable.foreignKey(["siteID", "productID"], references: "product")
        }
    }

    private static func createProductVariationAttributeTable(_ db: Database) throws {
        try db.create(table: "productVariationAttribute") { productVariationAttributeTable in
            productVariationAttributeTable.primaryKey(["siteID", "attributeID"])

            productVariationAttributeTable.column("siteID", .integer).notNull()
            productVariationAttributeTable.column("productVariationID", .integer).notNull()
            productVariationAttributeTable.column("attributeID", .integer).notNull()

            productVariationAttributeTable.column("name", .text).notNull()
            productVariationAttributeTable.column("option", .text).notNull()

            productVariationAttributeTable.foreignKey(["siteID", "productVariationID"], references: "productVariation")
        }
    }

    private static func createProductVariationImageTable(_ db: Database) throws {
        try db.create(table: "productVariationImage") { productVariationImageTable in
            productVariationImageTable.primaryKey(["siteID", "imageID"])

            productVariationImageTable.column("siteID", .integer).notNull()
            productVariationImageTable.column("imageID", .integer).notNull()
            productVariationImageTable.column("productVariationID", .integer).notNull()

            productVariationImageTable.column("dateCreated", .datetime).notNull()
            productVariationImageTable.column("dateModified", .datetime)

            productVariationImageTable.column("src", .text).notNull()
            productVariationImageTable.column("name", .text)
            productVariationImageTable.column("alt", .text)

            productVariationImageTable.foreignKey(["siteID", "productVariationID"], references: "productVariation")
        }
    }
}
