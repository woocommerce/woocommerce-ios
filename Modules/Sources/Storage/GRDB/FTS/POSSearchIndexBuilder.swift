import Foundation
import GRDB

/// Builds and queries the FTS search index for Point of Sale products and variations.
public struct POSSearchIndexBuilder {
    /// Rebuilds the FTS search index for a site by clearing existing entries and indexing
    /// all eligible products and variations.
    ///
    /// - Parameters:
    ///   - siteID: The site ID to rebuild the index for
    ///   - db: The database writer to use
    public static func rebuildIndex(for siteID: Int64, in db: any DatabaseWriter) async throws {
        try await db.write { db in
            try clearIndex(for: siteID, in: db)
            try indexAllProducts(siteID: siteID, in: db)
            try indexAllVariations(siteID: siteID, in: db)
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
            SELECT siteID, itemType, itemID, parentProductID
            FROM pos_search_fts
            WHERE pos_search_fts MATCH ?
              AND siteID = ?
            ORDER BY bm25(pos_search_fts)
            LIMIT ? OFFSET ?
        """, arguments: [ftsQuery, siteID, limit, offset])
    }

    /// Returns the total count of results matching the search term.
    public static func searchCount(siteID: Int64, term: String, in db: Database) throws -> Int {
        let ftsQuery = buildFTSQuery(from: term)
        guard !ftsQuery.isEmpty else { return 0 }

        return try Int.fetchOne(db, sql: """
            SELECT COUNT(*)
            FROM pos_search_fts
            WHERE pos_search_fts MATCH ?
              AND siteID = ?
        """, arguments: [ftsQuery, siteID]) ?? 0
    }

    /// Checks if the FTS index needs to be rebuilt for a site.
    /// Compares the index entry count against the total eligible products and variations.
    public static func needsRebuild(for siteID: Int64, in db: Database) throws -> Bool {
        let productCount = try PersistedProduct
            .posEligibleProductsRequest(siteID: siteID)
            .fetchCount(db)

        guard productCount > 0 else { return false }

        let variationCount = try PersistedProductVariation
            .posAllVariationsRequest(siteID: siteID)
            .fetchCount(db)

        let indexCount = try Int.fetchOne(db, sql: """
            SELECT COUNT(*) FROM pos_search_fts WHERE siteID = ?
        """, arguments: [siteID]) ?? 0

        return indexCount < productCount + variationCount
    }

    /// Clears the FTS index for a site.
    public static func clearIndex(for siteID: Int64, in db: Database) throws {
        try db.execute(sql: "DELETE FROM pos_search_fts WHERE siteID = ?", arguments: [siteID])
    }

    // MARK: - Private

    private static func buildFTSQuery(from term: String) -> String {
        let words = term.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }

        guard !words.isEmpty else { return "" }

        return words
            .map { word -> String in
                let escaped = word.replacingOccurrences(of: "\"", with: "\"\"")
                return "\"\(escaped)\"*"
            }
            .joined(separator: " ")
    }

    private static func indexAllProducts(siteID: Int64, in db: Database) throws {
        let products = try PersistedProduct
            .posEligibleProductsRequest(siteID: siteID)
            .fetchAll(db)

        for product in products {
            let searchableText = buildSearchableText(
                name: product.name,
                sku: product.sku,
                globalUniqueID: product.globalUniqueID,
                attributes: nil
            )

            try db.execute(
                sql: "INSERT INTO pos_search_fts (searchable_text, siteID, itemType, itemID, parentProductID) VALUES (?, ?, ?, ?, ?)",
                arguments: [searchableText, siteID, POSSearchIndex.ItemType.product.rawValue, product.id, nil as Int64?]
            )
        }
    }

    private static func indexAllVariations(siteID: Int64, in db: Database) throws {
        let variations = try PersistedProductVariation
            .posAllVariationsRequest(siteID: siteID)
            .fetchAll(db)

        for variation in variations {
            let parentProduct = try PersistedProduct.fetchOne(db, key: ["siteID": siteID, "id": variation.productID])

            let attributes = try PersistedProductVariationAttribute
                .filter(PersistedProductVariationAttribute.Columns.siteID == siteID)
                .filter(PersistedProductVariationAttribute.Columns.productVariationID == variation.id)
                .fetchAll(db)
                .map(\.option)

            let searchableText = buildSearchableText(
                name: parentProduct?.name,
                sku: variation.sku,
                globalUniqueID: variation.globalUniqueID,
                attributes: attributes.joined(separator: " ")
            )

            try db.execute(
                sql: "INSERT INTO pos_search_fts (searchable_text, siteID, itemType, itemID, parentProductID) VALUES (?, ?, ?, ?, ?)",
                arguments: [searchableText, siteID, POSSearchIndex.ItemType.variation.rawValue, variation.id, variation.productID]
            )
        }
    }

    private static func buildSearchableText(name: String?, sku: String?, globalUniqueID: String?, attributes: String?) -> String {
        [name, sku, globalUniqueID, attributes]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
