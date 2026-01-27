import Foundation
import GRDB

/// Builds and queries the FTS search index for Point of Sale products and variations.
public struct POSSearchIndexBuilder {
    /// Rebuilds the FTS search index for a site by clearing existing entries and indexing
    /// all eligible products and variations.
    /// - Parameters:
    ///   - siteID: The site ID to rebuild the index for
    ///   - db: The database writer to use
    public static func rebuildIndex(for siteID: Int64, in db: any DatabaseWriter) async throws {
        try await db.write { db in
            // Clear existing FTS entries for this site
            let existingRowids = try Int64.fetchAll(db, sql: """
                SELECT rowid FROM posSearchIndex WHERE siteID = ?
            """, arguments: [siteID])

            if !existingRowids.isEmpty {
                let placeholders = existingRowids.map { _ in "?" }.joined(separator: ",")
                try db.execute(sql: "DELETE FROM pos_search_fts WHERE rowid IN (\(placeholders))",
                              arguments: StatementArguments(existingRowids))
            }

            // Clear mapping table
            try db.execute(sql: "DELETE FROM posSearchIndex WHERE siteID = ?", arguments: [siteID])

            // Index simple products
            try indexProducts(siteID: siteID, productType: "simple", itemType: .simpleProduct, in: db)

            // Index variable products
            try indexProducts(siteID: siteID, productType: "variable", itemType: .variableProduct, in: db)

            // Index variations
            try indexVariations(siteID: siteID, in: db)
        }
    }

    /// Searches the FTS index for products and variations matching the search term.
    /// - Parameters:
    ///   - siteID: The site ID to search within
    ///   - term: The search term
    ///   - limit: Maximum number of results (default 50)
    ///   - offset: Number of results to skip (default 0)
    ///   - db: The database to search in
    /// - Returns: Array of matching POSSearchIndex entries, ordered by BM25 relevance
    public static func search(siteID: Int64, term: String, limit: Int = 50, offset: Int = 0, in db: Database) throws -> [POSSearchIndex] {
        let ftsQuery = buildFTSQuery(from: term)
        guard !ftsQuery.isEmpty else { return [] }

        return try POSSearchIndex.fetchAll(db, sql: """
            SELECT idx.*
            FROM pos_search_fts fts
            JOIN posSearchIndex idx ON fts.rowid = idx.rowid
            WHERE idx.siteID = ?
              AND fts.pos_search_fts MATCH ?
            ORDER BY bm25(pos_search_fts)
            LIMIT ? OFFSET ?
        """, arguments: [siteID, ftsQuery, limit, offset])
    }

    /// Returns the total count of results matching the search term.
    /// - Parameters:
    ///   - siteID: The site ID to search within
    ///   - term: The search term
    ///   - db: The database to search in
    /// - Returns: Total count of matching results
    public static func searchCount(siteID: Int64, term: String, in db: Database) throws -> Int {
        let ftsQuery = buildFTSQuery(from: term)
        guard !ftsQuery.isEmpty else { return 0 }

        return try Int.fetchOne(db, sql: """
            SELECT COUNT(*)
            FROM pos_search_fts fts
            JOIN posSearchIndex idx ON fts.rowid = idx.rowid
            WHERE idx.siteID = ?
              AND fts.pos_search_fts MATCH ?
        """, arguments: [siteID, ftsQuery]) ?? 0
    }

    // MARK: - Private

    private static func buildFTSQuery(from term: String) -> String {
        term
            .split(separator: " ")
            .filter { !$0.isEmpty }
            .map { word -> String in
                // Escape double quotes within the word and wrap in quotes for literal matching
                let escaped = word.replacingOccurrences(of: "\"", with: "\"\"")
                return "\"\(escaped)\"*"
            }
            .joined(separator: " ")
    }

    private static func indexProducts(siteID: Int64, productType: String, itemType: POSSearchIndex.ItemType, in db: Database) throws {
        let products = try Row.fetchAll(db, sql: """
            SELECT id, name, sku, globalUniqueID
            FROM product
            WHERE siteID = ?
              AND productTypeKey = ?
              AND downloadable = 0
              AND statusKey NOT IN ('trash', 'draft', 'pending')
        """, arguments: [siteID, productType])

        for product in products {
            let searchableText = buildSearchableText(
                name: product["name"],
                sku: product["sku"],
                globalUniqueID: product["globalUniqueID"],
                attributes: nil
            )

            try db.execute(sql: "INSERT INTO pos_search_fts (searchable_text) VALUES (?)",
                          arguments: [searchableText])
            let rowid = db.lastInsertedRowID

            let index = POSSearchIndex(
                rowid: rowid,
                siteID: siteID,
                itemType: itemType,
                itemID: product["id"],
                parentProductID: nil
            )
            try index.insert(db)
        }
    }

    private static func indexVariations(siteID: Int64, in db: Database) throws {
        let variations = try Row.fetchAll(db, sql: """
            SELECT v.id, v.productID, v.sku, v.globalUniqueID, p.name as parentName
            FROM productVariation v
            JOIN product p ON v.siteID = p.siteID AND v.productID = p.id
            WHERE v.siteID = ?
              AND v.downloadable = 0
        """, arguments: [siteID])

        for variation in variations {
            let variationID: Int64 = variation["id"]

            let attributes = try String.fetchAll(db, sql: """
                SELECT option FROM productVariationAttribute
                WHERE siteID = ? AND productVariationID = ?
            """, arguments: [siteID, variationID])

            let searchableText = buildSearchableText(
                name: variation["parentName"],
                sku: variation["sku"],
                globalUniqueID: variation["globalUniqueID"],
                attributes: attributes.joined(separator: " ")
            )

            try db.execute(sql: "INSERT INTO pos_search_fts (searchable_text) VALUES (?)",
                          arguments: [searchableText])
            let rowid = db.lastInsertedRowID

            let index = POSSearchIndex(
                rowid: rowid,
                siteID: siteID,
                itemType: .variation,
                itemID: variationID,
                parentProductID: variation["productID"]
            )
            try index.insert(db)
        }
    }

    private static func buildSearchableText(name: String?, sku: String?, globalUniqueID: String?, attributes: String?) -> String {
        [name, sku, globalUniqueID, attributes]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
