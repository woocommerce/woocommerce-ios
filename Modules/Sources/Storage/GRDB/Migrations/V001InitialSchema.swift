import Foundation
import GRDB

struct V001InitialSchema {
    // This migration is under development and not released yet.
    // It's still open for modification, until we ship.
    // TODO: Mark this as final when we enable the pointOfSaleLocalCatalogi1 feature flag

    static func migrate(_ db: Database) throws {
        try createSiteTable(db)
        try createProductTable(db)
        try createProductAttributeTable(db)
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
        }
    }

    private static func createProductAttributeTable(_ db: Database) throws {
        try db.create(table: "productAttribute") { productAttributeTable in
            // This table holds local product attributes only. Global attributes belong to a site.
            productAttributeTable.autoIncrementedPrimaryKey("id").notNull()
            productAttributeTable.column("siteID", .integer).notNull()
            productAttributeTable.column("productID", .integer).notNull()
            productAttributeTable.foreignKey(["siteID", "productID"],
                                             references: "product",
                                             columns: ["siteID", "id"],
                                             onDelete: .cascade)

            productAttributeTable.column("name", .text).notNull()
            productAttributeTable.column("position", .integer).notNull()
            productAttributeTable.column("visible", .boolean).notNull()
            productAttributeTable.column("variation", .boolean).notNull()
            productAttributeTable.column("options", .jsonText).notNull()
        }
    }

    private static func createProductImageTable(_ db: Database) throws {
        try db.create(table: "productImage") { productImageTable in
            productImageTable.column("siteID", .integer).notNull()
            productImageTable.column("id", .integer).notNull()
            productImageTable.primaryKey(["siteID", "id"])
            productImageTable.column("productID", .integer).notNull()
            productImageTable.foreignKey(["siteID", "productID"],
                                         references: "product",
                                         columns: ["siteID", "id"],
                                         onDelete: .cascade)

            productImageTable.column("dateCreated", .datetime).notNull()
            productImageTable.column("dateModified", .datetime)

            productImageTable.column("src", .text).notNull()
            productImageTable.column("name", .text)
            productImageTable.column("alt", .text)
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
            // This table holds local variation attributes only. Global attributes belong to a site.
            productVariationAttributeTable.autoIncrementedPrimaryKey("id").notNull()
            productVariationAttributeTable.column("siteID", .integer).notNull()
            productVariationAttributeTable.column("productVariationID", .integer).notNull()
            productVariationAttributeTable.foreignKey(["siteID", "productVariationID"],
                                                      references: "productVariation",
                                                      columns: ["siteID", "id"],
                                                      onDelete: .cascade)

            productVariationAttributeTable.column("name", .text).notNull()
            productVariationAttributeTable.column("option", .text).notNull()
        }
    }

    private static func createProductVariationImageTable(_ db: Database) throws {
        try db.create(table: "productVariationImage") { productVariationImageTable in
            productVariationImageTable.column("siteID", .integer).notNull()
            productVariationImageTable.column("id", .integer).notNull()
            productVariationImageTable.primaryKey(["siteID", "id"])
            productVariationImageTable.column("productVariationID", .integer).notNull()
            productVariationImageTable.foreignKey(["siteID", "productVariationID"],
                                                  references: "productVariation",
                                                  columns: ["siteID", "id"],
                                                  onDelete: .cascade)

            productVariationImageTable.column("dateCreated", .datetime).notNull()
            productVariationImageTable.column("dateModified", .datetime)

            productVariationImageTable.column("src", .text).notNull()
            productVariationImageTable.column("name", .text)
            productVariationImageTable.column("alt", .text)
        }
    }
}
