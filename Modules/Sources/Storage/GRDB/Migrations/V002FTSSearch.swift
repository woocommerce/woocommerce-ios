import Foundation
import GRDB

struct V002FTSSearch {
    static func migrate(_ db: Database) throws {
        try createSearchFTSTable(db)
        try createSearchIndexTable(db)
        try populateIndexFromExistingData(db)
    }

    private static func createSearchFTSTable(_ db: Database) throws {
        try db.execute(sql: """
            CREATE VIRTUAL TABLE pos_search_fts USING fts5(
                searchable_text,
                content='',
                contentless_delete=1
            )
        """)
    }

    private static func createSearchIndexTable(_ db: Database) throws {
        try db.create(table: "posSearchIndex") { table in
            table.column("rowid", .integer).primaryKey()
            table.column("siteID", .integer).notNull()
            table.foreignKey(["siteID"], references: "site", columns: ["id"], onDelete: .cascade)
            table.column("itemType", .text).notNull()
            table.column("itemID", .integer).notNull()
            table.column("parentProductID", .integer)
        }
    }

    private static func populateIndexFromExistingData(_ db: Database) throws {
        // Get all sites
        let siteIDs = try Int64.fetchAll(db, sql: "SELECT id FROM site")

        for siteID in siteIDs {
            try populateIndexForSite(siteID, in: db)
        }
    }

    private static func populateIndexForSite(_ siteID: Int64, in db: Database) throws {
        // Index simple products
        let simpleProducts = try Row.fetchAll(db, sql: """
            SELECT id, name, sku, globalUniqueID
            FROM product
            WHERE siteID = ?
              AND productTypeKey = 'simple'
              AND downloadable = 0
              AND statusKey NOT IN ('trash', 'draft', 'pending')
        """, arguments: [siteID])

        for product in simpleProducts {
            try indexProduct(product, siteID: siteID, itemType: "simpleProduct", in: db)
        }

        // Index variable products
        let variableProducts = try Row.fetchAll(db, sql: """
            SELECT id, name, sku, globalUniqueID
            FROM product
            WHERE siteID = ?
              AND productTypeKey = 'variable'
              AND downloadable = 0
              AND statusKey NOT IN ('trash', 'draft', 'pending')
        """, arguments: [siteID])

        for product in variableProducts {
            try indexProduct(product, siteID: siteID, itemType: "variableProduct", in: db)
        }

        // Index variations
        let variations = try Row.fetchAll(db, sql: """
            SELECT v.id, v.productID, v.sku, v.globalUniqueID, p.name as parentName
            FROM productVariation v
            JOIN product p ON v.siteID = p.siteID AND v.productID = p.id
            WHERE v.siteID = ?
              AND v.downloadable = 0
        """, arguments: [siteID])

        for variation in variations {
            try indexVariation(variation, siteID: siteID, in: db)
        }
    }

    private static func indexProduct(_ row: Row, siteID: Int64, itemType: String, in db: Database) throws {
        let id: Int64 = row["id"]
        let name: String = row["name"]
        let sku: String? = row["sku"]
        let globalUniqueID: String? = row["globalUniqueID"]

        let searchableText = [name, sku, globalUniqueID]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        try db.execute(sql: "INSERT INTO pos_search_fts (searchable_text) VALUES (?)", arguments: [searchableText])
        let rowid = db.lastInsertedRowID

        try db.execute(sql: """
            INSERT INTO posSearchIndex (rowid, siteID, itemType, itemID, parentProductID)
            VALUES (?, ?, ?, ?, NULL)
        """, arguments: [rowid, siteID, itemType, id])
    }

    private static func indexVariation(_ row: Row, siteID: Int64, in db: Database) throws {
        let id: Int64 = row["id"]
        let productID: Int64 = row["productID"]
        let parentName: String = row["parentName"]
        let sku: String? = row["sku"]
        let globalUniqueID: String? = row["globalUniqueID"]

        // Fetch variation attributes
        let attributes = try String.fetchAll(db, sql: """
            SELECT option FROM productVariationAttribute
            WHERE siteID = ? AND productVariationID = ?
        """, arguments: [siteID, id])

        let attributeText = attributes.joined(separator: " ")

        let searchableText = [parentName, attributeText, sku, globalUniqueID]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        try db.execute(sql: "INSERT INTO pos_search_fts (searchable_text) VALUES (?)", arguments: [searchableText])
        let rowid = db.lastInsertedRowID

        try db.execute(sql: """
            INSERT INTO posSearchIndex (rowid, siteID, itemType, itemID, parentProductID)
            VALUES (?, ?, 'variation', ?, ?)
        """, arguments: [rowid, siteID, id, productID])
    }
}
