import Foundation
import GRDB

struct V001InitialSchema {
    static func migrate(_ db: Database) throws {
        try createSiteTable(db)
        try createProductTable(db)
        try createProductAttributeTable(db)
        try createImageTable(db)
        try createProductImageTable(db)
        try createProductVariationTable(db)
        try createProductVariationAttributeTable(db)
        try createProductVariationImageTable(db)
    }

    static func createSiteTable(_ db: Database) throws {
        try db.create(table: "site") { siteTable in
            siteTable.primaryKey("id", .integer).notNull()
            siteTable.column("lastCatalogIncrementalSyncDate", .datetime)
            siteTable.column("lastCatalogFullSyncDate", .datetime)
        }
    }

    static func createProductTable(_ db: Database) throws {
        // Note that it's best to use strings for names in the database
        // not derive them from a Swift class.
        // https://swiftpackageindex.com/groue/grdb.swift/v7.6.1/documentation/grdb/migrations#Good-Practices-for-Defining-Migrations
        try db.create(table: "product") { productTable in
            productTable.column("id", .integer).notNull()
            productTable.primaryKey(["siteID", "id"]) // SiteID column created by belongsTo relationship
            productTable.belongsTo("site", onDelete: .cascade).notNull()

            productTable.column("name", .text).notNull()
            productTable.column("productTypeKey", .text).notNull()

            productTable.column("fullDescription", .text)
            productTable.column("shortDescription", .text)

            productTable.column("sku", .text)
            productTable.column("globalUniqueID", .text)
            productTable.column("price", .text).notNull()

            productTable.column("downloadable", .boolean).notNull()

            productTable.column("parentID", .integer).notNull()

            productTable.column("manageStock", .boolean).notNull()
            productTable.column("stockQuantity", .double)
            productTable.column("stockStatusKey", .text).notNull()

            productTable.column("statusKey", .text).notNull()
        }
    }

    private static func createProductAttributeTable(_ db: Database) throws {
        try db.create(table: "productAttribute") { productAttributeTable in
            // This table holds both local and global product attributes.
            // Local attributes have remoteAttributeID = 0, global attributes have remoteAttributeID > 0
            productAttributeTable.autoIncrementedPrimaryKey("id").notNull()
            productAttributeTable.column("siteID", .integer).notNull()
            productAttributeTable.column("productID", .integer).notNull()
            productAttributeTable.foreignKey(["siteID", "productID"],
                                             references: "product",
                                             columns: ["siteID", "id"],
                                             onDelete: .cascade)

            productAttributeTable.column("remoteAttributeID", .integer).notNull()
            productAttributeTable.column("name", .text).notNull()
            productAttributeTable.column("position", .integer).notNull()
            productAttributeTable.column("visible", .boolean).notNull()
            productAttributeTable.column("variation", .boolean).notNull()
            productAttributeTable.column("options", .jsonText).notNull()
        }
    }

    private static func createImageTable(_ db: Database) throws {
        // Single image table shared by products and variations
        try db.create(table: "image") { imageTable in
            imageTable.column("id", .integer).notNull()
            imageTable.primaryKey(["siteID", "id"]) // SiteID column created by belongsTo relationship
            imageTable.belongsTo("site", onDelete: .cascade)

            imageTable.column("dateCreated", .datetime).notNull()
            imageTable.column("dateModified", .datetime)

            imageTable.column("src", .text).notNull()
            imageTable.column("name", .text)
            imageTable.column("alt", .text)
        }
    }

    private static func createProductImageTable(_ db: Database) throws {
        // Join table for many-to-many relationship between products and images
        try db.create(table: "productImage") { productImageTable in
            productImageTable.column("siteID", .integer).notNull()
            productImageTable.column("productID", .integer).notNull()
            productImageTable.column("imageID", .integer).notNull()
            productImageTable.primaryKey(["siteID", "productID", "imageID"])

            productImageTable.foreignKey(["siteID", "productID"],
                                         references: "product",
                                         columns: ["siteID", "id"],
                                         onDelete: .cascade)

            productImageTable.foreignKey(["siteID", "imageID"],
                                         references: "image",
                                         columns: ["siteID", "id"],
                                         onDelete: .cascade)
        }
    }

    private static func createProductVariationTable(_ db: Database) throws {
        try db.create(table: "productVariation") { productVariationTable in
            productVariationTable.column("id", .integer).notNull()
            productVariationTable.primaryKey(["siteID", "id"]) // SiteID column created by belongsTo relationship
            productVariationTable.column("productID", .integer).notNull()
            productVariationTable.belongsTo("site", onDelete: .cascade).notNull()
            productVariationTable.foreignKey(["siteID", "productID"],
                                             references: "product",
                                             columns: ["siteID", "id"],
                                             onDelete: .cascade)

            productVariationTable.column("sku", .text)
            productVariationTable.column("globalUniqueID", .text)
            productVariationTable.column("price", .text).notNull()

            productVariationTable.column("downloadable", .boolean).notNull()

            productVariationTable.column("fullDescription", .text)

            productVariationTable.column("manageStock", .boolean).notNull()
            productVariationTable.column("stockQuantity", .double)
            productVariationTable.column("stockStatusKey", .text).notNull()
        }
    }

    private static func createProductVariationAttributeTable(_ db: Database) throws {
        try db.create(table: "productVariationAttribute") { productVariationAttributeTable in
            // This table holds both local and global variation attributes.
            // Local attributes have remoteAttributeID = 0, global attributes have remoteAttributeID > 0
            productVariationAttributeTable.autoIncrementedPrimaryKey("id").notNull()
            productVariationAttributeTable.column("siteID", .integer).notNull()
            productVariationAttributeTable.column("productVariationID", .integer).notNull()
            productVariationAttributeTable.foreignKey(["siteID", "productVariationID"],
                                                      references: "productVariation",
                                                      columns: ["siteID", "id"],
                                                      onDelete: .cascade)

            productVariationAttributeTable.column("remoteAttributeID", .integer).notNull()
            productVariationAttributeTable.column("name", .text).notNull()
            productVariationAttributeTable.column("option", .text).notNull()
        }
    }

    private static func createProductVariationImageTable(_ db: Database) throws {
        // Join table for many-to-many relationship between product variations and images
        try db.create(table: "productVariationImage") { productVariationImageTable in
            productVariationImageTable.column("siteID", .integer).notNull()
            productVariationImageTable.column("productVariationID", .integer).notNull()
            productVariationImageTable.column("imageID", .integer).notNull()
            productVariationImageTable.primaryKey(["siteID", "productVariationID", "imageID"])

            productVariationImageTable.foreignKey(["siteID", "productVariationID"],
                                                  references: "productVariation",
                                                  columns: ["siteID", "id"],
                                                  onDelete: .cascade)

            productVariationImageTable.foreignKey(["siteID", "imageID"],
                                                  references: "image",
                                                  columns: ["siteID", "id"],
                                                  onDelete: .cascade)
        }
    }
}
