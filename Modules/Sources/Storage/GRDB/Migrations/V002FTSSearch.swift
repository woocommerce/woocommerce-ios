import Foundation
import GRDB

struct V002FTSSearch {
    static func migrate(_ db: Database) throws {
        try createSearchFTSTable(db)
        // Data population moved to POS open time via POSSearchIndexBuilder.rebuildIndex
        // This prevents blocking app startup for users with large catalogs
    }

    private static func createSearchFTSTable(_ db: Database) throws {
        try db.create(virtualTable: "pos_search_fts", using: FTS5()) { t in
            t.column("searchable_text")
            t.column("siteID").notIndexed()
            t.column("itemType").notIndexed()
            t.column("itemID").notIndexed()
            t.column("parentProductID").notIndexed()
        }
    }
}
