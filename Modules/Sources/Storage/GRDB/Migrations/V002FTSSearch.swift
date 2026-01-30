import Foundation
import GRDB

struct V002FTSSearch {
    static func migrate(_ db: Database) throws {
        try createSearchFTSTable(db)
        // Data population moved to POS open time via POSSearchIndexBuilder.rebuildIndex
        // This prevents blocking app startup for users with large catalogs
    }

    private static func createSearchFTSTable(_ db: Database) throws {
        try db.execute(sql: """
            CREATE VIRTUAL TABLE pos_search_fts USING fts5(
                searchable_text,
                siteID UNINDEXED,
                itemType UNINDEXED,
                itemID UNINDEXED,
                parentProductID UNINDEXED
            )
        """)
    }
}
