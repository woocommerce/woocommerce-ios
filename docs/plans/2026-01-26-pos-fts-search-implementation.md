# POS Full-Text Search Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add FTS5-based search to Point of Sale for products and variations with relevance ranking.

**Architecture:** Single unified FTS5 virtual table indexes both products and variations. A mapping table links FTS rowids to source records. Search returns mixed product/variation results ranked by BM25 relevance.

**Tech Stack:** GRDB, SQLite FTS5, Swift Testing

---

## PR Structure

This implementation is split into 5 small PRs (each ~100-200 lines excluding tests):

| PR | Description | Dependencies |
|----|-------------|--------------|
| PR 1 | FTS schema migration & POSSearchIndex model | None |
| PR 2 | POSSearchIndexBuilder (rebuild & search) | PR 1 |
| PR 3 | Catalog persistence integration | PR 2 |
| PR 4 | UI: searchResultVariation case & card view | None (can parallel with PR 2-3) |
| PR 5 | Search strategy FTS integration | PR 1-4 |

---

# PR 1: FTS Schema & Model

**Estimated lines:** ~120 (excluding tests)

## Task 1.1: Create FTS Migration File

**Files:**
- Create: `Modules/Sources/Storage/GRDB/Migrations/V002FTSSearch.swift`

**Step 1: Create the migration file**

Create file at `Modules/Sources/Storage/GRDB/Migrations/V002FTSSearch.swift`:

```swift
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
```

**Step 2: Commit**

```bash
git add Modules/Sources/Storage/GRDB/Migrations/V002FTSSearch.swift
git commit -m "$(cat <<'EOF'
Add V002FTSSearch migration for FTS tables

Creates pos_search_fts virtual table and posSearchIndex mapping table.
Populates index from existing catalog data during migration.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 1.2: Register Migration in GRDBManager

**Files:**
- Modify: `Modules/Sources/Storage/GRDB/GRDBManager.swift`

**Step 1: Add migration registration**

In GRDBManager.swift, update migrateIfNeeded():

```swift
private extension GRDBManager {
    func migrateIfNeeded() throws {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("V001InitialSchema") { db in
            try V001InitialSchema.migrate(db)
        }

        migrator.registerMigration("V002FTSSearch") { db in
            try V002FTSSearch.migrate(db)
        }

        try migrator.migrate(databaseConnection)
    }
}
```

**Step 2: Commit**

```bash
git add Modules/Sources/Storage/GRDB/GRDBManager.swift
git commit -m "$(cat <<'EOF'
Register V002FTSSearch migration in GRDBManager

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 1.3: Create POSSearchIndex Model

**Files:**
- Create: `Modules/Sources/Storage/GRDB/Model/POSSearchIndex.swift`
- Test: `Modules/Tests/StorageTests/GRDB/POSSearchIndexTests.swift`

**Step 1: Write the test file**

Create test file at `Modules/Tests/StorageTests/GRDB/POSSearchIndexTests.swift`:

```swift
import Foundation
import Testing
import GRDB
@testable import Storage

@Suite("POSSearchIndex Tests")
struct POSSearchIndexTests {
    private let siteID: Int64 = 123
    private var grdbManager: GRDBManager!

    init() async throws {
        grdbManager = try GRDBManager()
        try await grdbManager.databaseConnection.write { db in
            try PersistedSite(id: 123).insert(db)
        }
    }

    @Test("POSSearchIndex can be inserted and fetched")
    func test_insert_and_fetch() async throws {
        // Given
        let index = POSSearchIndex(
            rowid: 1,
            siteID: siteID,
            itemType: .simpleProduct,
            itemID: 100,
            parentProductID: nil
        )

        // When
        try await grdbManager.databaseConnection.write { db in
            try index.insert(db)
        }

        // Then
        let fetched = try await grdbManager.databaseConnection.read { db in
            try POSSearchIndex.fetchOne(db, key: 1)
        }
        #expect(fetched?.itemType == .simpleProduct)
        #expect(fetched?.itemID == 100)
    }

    @Test("POSSearchIndex variation stores parentProductID")
    func test_variation_stores_parent_product_id() async throws {
        // Given
        let index = POSSearchIndex(
            rowid: 2,
            siteID: siteID,
            itemType: .variation,
            itemID: 200,
            parentProductID: 100
        )

        // When
        try await grdbManager.databaseConnection.write { db in
            try index.insert(db)
        }

        // Then
        let fetched = try await grdbManager.databaseConnection.read { db in
            try POSSearchIndex.fetchOne(db, key: 2)
        }
        #expect(fetched?.itemType == .variation)
        #expect(fetched?.parentProductID == 100)
    }

    @Test("POSSearchIndex cascades delete with site")
    func test_cascades_delete_with_site() async throws {
        // Given
        let index = POSSearchIndex(
            rowid: 3,
            siteID: siteID,
            itemType: .simpleProduct,
            itemID: 300,
            parentProductID: nil
        )
        try await grdbManager.databaseConnection.write { db in
            try index.insert(db)
        }

        // When
        try await grdbManager.databaseConnection.write { db in
            try PersistedSite.deleteOne(db, key: siteID)
        }

        // Then
        let fetched = try await grdbManager.databaseConnection.read { db in
            try POSSearchIndex.fetchOne(db, key: 3)
        }
        #expect(fetched == nil)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `cd /Users/joshheald/Development/woocommerce-ios && xcodebuild test -workspace WooCommerce.xcworkspace -scheme WooCommerce -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:StorageTests/POSSearchIndexTests 2>&1 | xcpretty`

Expected: Build failure - POSSearchIndex not defined

**Step 3: Create the POSSearchIndex model**

Create file at `Modules/Sources/Storage/GRDB/Model/POSSearchIndex.swift`:

```swift
import Foundation
import GRDB

public struct POSSearchIndex: Codable, Equatable {
    public let rowid: Int64
    public let siteID: Int64
    public let itemType: ItemType
    public let itemID: Int64
    public let parentProductID: Int64?

    public enum ItemType: String, Codable {
        case simpleProduct
        case variableProduct
        case variation
    }

    public init(rowid: Int64,
                siteID: Int64,
                itemType: ItemType,
                itemID: Int64,
                parentProductID: Int64?) {
        self.rowid = rowid
        self.siteID = siteID
        self.itemType = itemType
        self.itemID = itemID
        self.parentProductID = parentProductID
    }
}

extension POSSearchIndex: FetchableRecord, PersistableRecord {
    public static var databaseTableName: String { "posSearchIndex" }

    public enum Columns {
        public static let rowid = Column(CodingKeys.rowid)
        public static let siteID = Column(CodingKeys.siteID)
        public static let itemType = Column(CodingKeys.itemType)
        public static let itemID = Column(CodingKeys.itemID)
        public static let parentProductID = Column(CodingKeys.parentProductID)
    }
}

private extension POSSearchIndex {
    enum CodingKeys: String, CodingKey {
        case rowid
        case siteID
        case itemType
        case itemID
        case parentProductID
    }
}
```

**Step 4: Run test to verify it passes**

Run: `cd /Users/joshheald/Development/woocommerce-ios && xcodebuild test -workspace WooCommerce.xcworkspace -scheme WooCommerce -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:StorageTests/POSSearchIndexTests 2>&1 | xcpretty`

Expected: All tests pass

**Step 5: Commit**

```bash
git add Modules/Sources/Storage/GRDB/Model/POSSearchIndex.swift Modules/Tests/StorageTests/GRDB/POSSearchIndexTests.swift
git commit -m "$(cat <<'EOF'
Add POSSearchIndex model for FTS result mapping

Maps FTS rowids to source product/variation records with item type
discriminator and optional parent product ID for variations.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 1.4: Create PR 1

```bash
git push -u origin feature/pos-fts-search
gh pr create --title "POS FTS Search: Schema & Model (1/5)" --body "$(cat <<'EOF'
## Summary
- Adds V002FTSSearch migration creating FTS5 virtual table and mapping table
- Creates POSSearchIndex model for mapping FTS results to source records
- Migration populates index from existing catalog data

## Test plan
- [ ] Run StorageTests/POSSearchIndexTests
- [ ] Verify migration runs on fresh install
- [ ] Verify migration runs on upgrade with existing catalog data

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

---

# PR 2: FTS Index Builder

**Estimated lines:** ~150 (excluding tests)

**Depends on:** PR 1

## Task 2.1: Create POSSearchIndexBuilder

**Files:**
- Create: `Modules/Sources/Storage/GRDB/FTS/POSSearchIndexBuilder.swift`
- Test: `Modules/Tests/StorageTests/GRDB/POSSearchIndexBuilderTests.swift`

**Step 1: Write the test file**

Create test file at `Modules/Tests/StorageTests/GRDB/POSSearchIndexBuilderTests.swift`:

```swift
import Foundation
import Testing
import GRDB
@testable import Storage

@Suite("POSSearchIndexBuilder Tests")
struct POSSearchIndexBuilderTests {
    private let siteID: Int64 = 123
    private var grdbManager: GRDBManager!

    init() async throws {
        grdbManager = try GRDBManager()
        try await grdbManager.databaseConnection.write { db in
            try PersistedSite(id: 123).insert(db)
        }
    }

    @Test("rebuildIndex indexes simple products")
    func test_rebuild_indexes_simple_products() async throws {
        // Given
        try await insertProduct(id: 1, name: "Coffee Beans", productTypeKey: "simple")

        // When
        try await POSSearchIndexBuilder.rebuildIndex(for: siteID, in: grdbManager.databaseConnection)

        // Then
        let count = try await grdbManager.databaseConnection.read { db in
            try POSSearchIndex.filter(POSSearchIndex.Columns.siteID == siteID).fetchCount(db)
        }
        #expect(count == 1)
    }

    @Test("rebuildIndex indexes variable products")
    func test_rebuild_indexes_variable_products() async throws {
        // Given
        try await insertProduct(id: 1, name: "T-Shirt", productTypeKey: "variable")

        // When
        try await POSSearchIndexBuilder.rebuildIndex(for: siteID, in: grdbManager.databaseConnection)

        // Then
        let index = try await grdbManager.databaseConnection.read { db in
            try POSSearchIndex.filter(POSSearchIndex.Columns.itemID == 1).fetchOne(db)
        }
        #expect(index?.itemType == .variableProduct)
    }

    @Test("rebuildIndex indexes variations with attributes")
    func test_rebuild_indexes_variations() async throws {
        // Given
        try await insertProduct(id: 1, name: "T-Shirt", productTypeKey: "variable")
        try await insertVariation(id: 100, productID: 1)
        try await insertVariationAttribute(variationID: 100, name: "Size", option: "Large")

        // When
        try await POSSearchIndexBuilder.rebuildIndex(for: siteID, in: grdbManager.databaseConnection)

        // Then
        let index = try await grdbManager.databaseConnection.read { db in
            try POSSearchIndex
                .filter(POSSearchIndex.Columns.itemType == POSSearchIndex.ItemType.variation.rawValue)
                .fetchOne(db)
        }
        #expect(index?.itemID == 100)
        #expect(index?.parentProductID == 1)
    }

    @Test("rebuildIndex clears existing index before rebuilding")
    func test_rebuild_clears_existing_index() async throws {
        // Given
        try await insertProduct(id: 1, name: "Coffee", productTypeKey: "simple")
        try await POSSearchIndexBuilder.rebuildIndex(for: siteID, in: grdbManager.databaseConnection)

        // Delete product and add new one
        try await grdbManager.databaseConnection.write { db in
            try PersistedProduct.deleteOne(db, key: ["siteID": siteID, "id": 1])
        }
        try await insertProduct(id: 2, name: "Tea", productTypeKey: "simple")

        // When
        try await POSSearchIndexBuilder.rebuildIndex(for: siteID, in: grdbManager.databaseConnection)

        // Then
        let count = try await grdbManager.databaseConnection.read { db in
            try POSSearchIndex.filter(POSSearchIndex.Columns.siteID == siteID).fetchCount(db)
        }
        #expect(count == 1)
    }

    @Test("search finds products by name")
    func test_search_finds_by_name() async throws {
        // Given
        try await insertProduct(id: 1, name: "Coffee Beans Dark Roast", productTypeKey: "simple")
        try await insertProduct(id: 2, name: "Tea Leaves", productTypeKey: "simple")
        try await POSSearchIndexBuilder.rebuildIndex(for: siteID, in: grdbManager.databaseConnection)

        // When
        let results = try await grdbManager.databaseConnection.read { db in
            try POSSearchIndexBuilder.search(siteID: siteID, term: "coffee", in: db)
        }

        // Then
        #expect(results.count == 1)
        #expect(results.first?.itemID == 1)
    }

    @Test("search finds products by SKU")
    func test_search_finds_by_sku() async throws {
        // Given
        try await insertProduct(id: 1, name: "Product A", sku: "SKU-COFFEE-123", productTypeKey: "simple")
        try await insertProduct(id: 2, name: "Product B", sku: "SKU-TEA-456", productTypeKey: "simple")
        try await POSSearchIndexBuilder.rebuildIndex(for: siteID, in: grdbManager.databaseConnection)

        // When
        let results = try await grdbManager.databaseConnection.read { db in
            try POSSearchIndexBuilder.search(siteID: siteID, term: "COFFEE", in: db)
        }

        // Then
        #expect(results.count == 1)
        #expect(results.first?.itemID == 1)
    }

    @Test("search matches words in any order")
    func test_search_matches_any_order() async throws {
        // Given
        try await insertProduct(id: 1, name: "Dark Roast Coffee", productTypeKey: "simple")
        try await POSSearchIndexBuilder.rebuildIndex(for: siteID, in: grdbManager.databaseConnection)

        // When
        let results = try await grdbManager.databaseConnection.read { db in
            try POSSearchIndexBuilder.search(siteID: siteID, term: "coffee dark", in: db)
        }

        // Then
        #expect(results.count == 1)
    }

    @Test("search uses prefix matching")
    func test_search_uses_prefix_matching() async throws {
        // Given
        try await insertProduct(id: 1, name: "Coffee", productTypeKey: "simple")
        try await POSSearchIndexBuilder.rebuildIndex(for: siteID, in: grdbManager.databaseConnection)

        // When
        let results = try await grdbManager.databaseConnection.read { db in
            try POSSearchIndexBuilder.search(siteID: siteID, term: "cof", in: db)
        }

        // Then
        #expect(results.count == 1)
    }

    @Test("search finds variations by attribute")
    func test_search_finds_variations_by_attribute() async throws {
        // Given
        try await insertProduct(id: 1, name: "T-Shirt", productTypeKey: "variable")
        try await insertVariation(id: 100, productID: 1)
        try await insertVariationAttribute(variationID: 100, name: "Size", option: "Extra Large")
        try await POSSearchIndexBuilder.rebuildIndex(for: siteID, in: grdbManager.databaseConnection)

        // When
        let results = try await grdbManager.databaseConnection.read { db in
            try POSSearchIndexBuilder.search(siteID: siteID, term: "extra large", in: db)
        }

        // Then
        #expect(results.count == 1)
        #expect(results.first?.itemType == .variation)
    }

    @Test("searchCount returns correct total")
    func test_searchCount_returns_correct_total() async throws {
        // Given
        for i in 1...25 {
            try await insertProduct(id: Int64(i), name: "Coffee Product \(i)", productTypeKey: "simple")
        }
        try await POSSearchIndexBuilder.rebuildIndex(for: siteID, in: grdbManager.databaseConnection)

        // When
        let count = try await grdbManager.databaseConnection.read { db in
            try POSSearchIndexBuilder.searchCount(siteID: siteID, term: "coffee", in: db)
        }

        // Then
        #expect(count == 25)
    }

    // MARK: - Helpers

    private func insertProduct(id: Int64, name: String, sku: String? = nil, productTypeKey: String) async throws {
        let product = PersistedProduct(
            id: id,
            siteID: siteID,
            name: name,
            productTypeKey: productTypeKey,
            fullDescription: nil,
            shortDescription: nil,
            sku: sku,
            globalUniqueID: nil,
            price: "10.00",
            downloadable: false,
            parentID: 0,
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock",
            statusKey: "publish"
        )
        try await grdbManager.databaseConnection.write { db in
            try product.insert(db)
        }
    }

    private func insertVariation(id: Int64, productID: Int64) async throws {
        let variation = PersistedProductVariation(
            id: id,
            siteID: siteID,
            productID: productID,
            sku: nil,
            globalUniqueID: nil,
            price: "10.00",
            downloadable: false,
            fullDescription: nil,
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock"
        )
        try await grdbManager.databaseConnection.write { db in
            try variation.insert(db)
        }
    }

    private func insertVariationAttribute(variationID: Int64, name: String, option: String) async throws {
        try await grdbManager.databaseConnection.write { db in
            var attribute = PersistedProductVariationAttribute(
                siteID: siteID,
                productVariationID: variationID,
                remoteAttributeID: 0,
                name: name,
                option: option
            )
            try attribute.insert(db)
        }
    }
}
```

**Step 2: Run test to verify it fails**

Expected: Build failure - POSSearchIndexBuilder not defined

**Step 3: Create POSSearchIndexBuilder**

Create file at `Modules/Sources/Storage/GRDB/FTS/POSSearchIndexBuilder.swift`:

```swift
import Foundation
import GRDB

public enum POSSearchIndexBuilder {

    /// Rebuilds the FTS search index for a site from scratch
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

    /// Searches the FTS index and returns matching index entries ordered by relevance
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

    /// Returns total count of search results
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
            .map { "\($0)*" }
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
```

**Step 4: Run tests**

Run: `cd /Users/joshheald/Development/woocommerce-ios && xcodebuild test -workspace WooCommerce.xcworkspace -scheme WooCommerce -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:StorageTests/POSSearchIndexBuilderTests 2>&1 | xcpretty`

Expected: All tests pass

**Step 5: Commit and create PR**

```bash
git add Modules/Sources/Storage/GRDB/FTS/POSSearchIndexBuilder.swift Modules/Tests/StorageTests/GRDB/POSSearchIndexBuilderTests.swift
git commit -m "$(cat <<'EOF'
Add POSSearchIndexBuilder for FTS operations

Provides rebuildIndex() to populate FTS from products/variations and
search()/searchCount() to query with BM25 relevance ranking.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"

git push
gh pr create --title "POS FTS Search: Index Builder (2/5)" --body "$(cat <<'EOF'
## Summary
- Adds POSSearchIndexBuilder with rebuild and search functionality
- Uses BM25 ranking for relevance-ordered results
- Supports prefix matching for search-as-you-type

## Test plan
- [ ] Run StorageTests/POSSearchIndexBuilderTests
- [ ] Test search finds products by name, SKU, barcode
- [ ] Test search finds variations by attributes
- [ ] Test words match in any order

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

---

# PR 3: Catalog Persistence Integration

**Estimated lines:** ~30 (excluding tests)

**Depends on:** PR 2

## Task 3.1: Integrate FTS Rebuild with Sync

**Files:**
- Modify: `Modules/Sources/Yosemite/Tools/POS/POSCatalogPersistenceService.swift`
- Modify: `Modules/Tests/YosemiteTests/Tools/POS/POSCatalogPersistenceServiceTests.swift`

**Step 1: Add test for FTS rebuild on full sync**

Add to POSCatalogPersistenceServiceTests.swift:

```swift
@Test("replaceAllCatalogData rebuilds FTS index")
func test_replaceAllCatalogData_rebuilds_fts_index() async throws {
    // Given
    let product = makeSimpleProduct(productID: 1, name: "Coffee Beans")
    let catalog = POSCatalog(products: [product], variations: [], syncDate: Date())

    // When
    try await sut.replaceAllCatalogData(catalog, siteID: siteID)

    // Then
    let indexCount = try await grdbManager.databaseConnection.read { db in
        try POSSearchIndex.filter(POSSearchIndex.Columns.siteID == siteID).fetchCount(db)
    }
    #expect(indexCount == 1)
}

@Test("persistIncrementalCatalogData rebuilds FTS index")
func test_persistIncrementalCatalogData_rebuilds_fts_index() async throws {
    // Given
    let product1 = makeSimpleProduct(productID: 1, name: "Coffee")
    let initialCatalog = POSCatalog(products: [product1], variations: [], syncDate: Date())
    try await sut.replaceAllCatalogData(initialCatalog, siteID: siteID)

    // When
    let product2 = makeSimpleProduct(productID: 2, name: "Tea")
    let incrementalCatalog = POSCatalog(products: [product2], variations: [], syncDate: Date())
    try await sut.persistIncrementalCatalogData(incrementalCatalog, siteID: siteID)

    // Then
    let indexCount = try await grdbManager.databaseConnection.read { db in
        try POSSearchIndex.filter(POSSearchIndex.Columns.siteID == siteID).fetchCount(db)
    }
    #expect(indexCount == 2)
}
```

**Step 2: Add FTS rebuild calls**

In POSCatalogPersistenceService.swift:

At the end of `replaceAllCatalogData`, after the logging block:
```swift
try await POSSearchIndexBuilder.rebuildIndex(for: siteID, in: grdbManager.databaseConnection)
DDLogInfo("✅ FTS search index rebuilt")
```

At the end of `persistIncrementalCatalogData`, after the logging block:
```swift
try await POSSearchIndexBuilder.rebuildIndex(for: siteID, in: grdbManager.databaseConnection)
DDLogInfo("✅ FTS search index rebuilt after incremental sync")
```

**Step 3: Run tests and commit**

```bash
git add Modules/Sources/Yosemite/Tools/POS/POSCatalogPersistenceService.swift Modules/Tests/YosemiteTests/Tools/POS/POSCatalogPersistenceServiceTests.swift
git commit -m "$(cat <<'EOF'
Integrate FTS index rebuild with catalog persistence

Rebuilds search index after both full and incremental sync operations.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"

git push
gh pr create --title "POS FTS Search: Sync Integration (3/5)" --body "$(cat <<'EOF'
## Summary
- Rebuilds FTS index after full catalog sync
- Rebuilds FTS index after incremental catalog sync

## Test plan
- [ ] Run POSCatalogPersistenceServiceTests
- [ ] Verify search works after full sync
- [ ] Verify search works after incremental sync

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

---

# PR 4: UI - searchResultVariation Case & Card

**Estimated lines:** ~150 (excluding tests)

**Can be developed in parallel with PR 2-3**

## Task 4.1: Add searchResultVariation to POSItem

**Files:**
- Modify: `Modules/Sources/Yosemite/PointOfSale/Items/PointOfSaleItemServiceProtocol.swift`

**Step 1: Add the new case**

Update POSItem enum:

```swift
public enum POSItem: Equatable, Identifiable, Hashable {
    case simpleProduct(POSSimpleProduct)
    case variableParentProduct(POSVariableParentProduct)
    case variation(POSVariation)
    case searchResultVariation(POSVariation, parentProduct: POSVariableParentProduct)
    case coupon(POSCoupon)

    public var id: POSItemIdentifier {
        switch self {
        case .simpleProduct(let product):
            return product.id
        case .variableParentProduct(let parentProduct):
            return parentProduct.id
        case .variation(let variation):
            return variation.id
        case .searchResultVariation(let variation, _):
            return variation.id
        case .coupon(let coupon):
            return coupon.id
        }
    }
}
```

**Step 2: Fix compile errors in dependent files**

Update any switch statements on POSItem to handle the new case. Typically treat `.searchResultVariation` the same as `.variation`.

**Step 3: Commit**

```bash
git add Modules/Sources/Yosemite/PointOfSale/Items/PointOfSaleItemServiceProtocol.swift
git commit -m "$(cat <<'EOF'
Add searchResultVariation case to POSItem

Carries both variation and parent product for search result display.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 4.2: Create SearchResultVariationCardView

**Files:**
- Create: `Modules/Sources/PointOfSale/Presentation/Item Selector/SearchResultVariationCardView.swift`

**Step 1: Create the view**

```swift
import SwiftUI
import struct Yosemite.POSVariation
import struct Yosemite.POSVariableParentProduct

struct SearchResultVariationCardView: View {
    private let variation: POSVariation
    private let parentProduct: POSVariableParentProduct

    @ScaledMetric private var scale: CGFloat = 1.0
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    private var dimension: CGFloat {
        min(Constants.productCardSize * scale, Constants.maximumProductCardSize)
    }

    init(variation: POSVariation, parentProduct: POSVariableParentProduct) {
        self.variation = variation
        self.parentProduct = parentProduct
    }

    var body: some View {
        HStack(spacing: Constants.cardSpacing) {
            POSItemImageView(
                imageSource: variation.productImageSource ?? parentProduct.productImageSource,
                imageSize: dimension,
                scale: 1
            )
            .frame(width: dimension, height: dimension)

            VStack(alignment: .leading, spacing: Constants.textSpacing) {
                Text(parentProduct.name)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                    .foregroundStyle(Constants.titleColor)
                    .multilineTextAlignment(.leading)
                    .font(Constants.itemTitleFont)

                Text(variation.name)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                    .foregroundStyle(Constants.subtitleColor)
                    .multilineTextAlignment(.leading)
                    .font(Constants.itemSubtitleFont)

                Text(variation.formattedPrice)
                    .foregroundStyle(Constants.detailColor)
                    .font(Constants.itemDetailFont)
            }
            .padding(.horizontal, Constants.horizontalTextPadding * (1 / scale))
            .padding(.vertical, Constants.verticalTextPadding * (1 / scale))

            Spacer()
        }
        .frame(maxWidth: .infinity, idealHeight: dynamicTypeSize.isAccessibilitySize ? nil : dimension)
        .background(Constants.backgroundColor)
        .posItemCardBorderStyles()
    }
}

private extension SearchResultVariationCardView {
    typealias Constants = PointOfSaleItemListCardConstants
}

#if DEBUG
#Preview("Search result variation") {
    let variation = POSVariation(
        id: .init(underlyingType: .variation, itemID: 100),
        name: "Large, Blue",
        formattedPrice: "$25.00",
        price: "25.00",
        productID: 1,
        variationID: 100,
        parentProductName: "T-Shirt"
    )
    let parentProduct = POSVariableParentProduct(
        id: .init(underlyingType: .product, itemID: 1),
        name: "T-Shirt",
        productImageSource: nil,
        productID: 1
    )
    SearchResultVariationCardView(variation: variation, parentProduct: parentProduct)
}
#endif
```

**Step 2: Commit**

```bash
git add "Modules/Sources/PointOfSale/Presentation/Item Selector/SearchResultVariationCardView.swift"
git commit -m "$(cat <<'EOF'
Add SearchResultVariationCardView

Shows parent product name as title and variation attributes as subtitle.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 4.3: Update ItemListRow

**Files:**
- Modify: `Modules/Sources/PointOfSale/Presentation/Item Selector/ItemList.swift`

**Step 1: Add case to ItemListRow**

```swift
case let .searchResultVariation(variation, parentProduct):
    Button(action: {
        itemActionHandler.handleTap(item)
    }, label: {
        SearchResultVariationCardView(variation: variation, parentProduct: parentProduct)
    })
    .accessibilityIdentifier("pos-search-variation-card-\(variation.productVariationID)")
```

**Step 2: Commit**

```bash
git add "Modules/Sources/PointOfSale/Presentation/Item Selector/ItemList.swift"
git commit -m "$(cat <<'EOF'
Handle searchResultVariation in ItemListRow

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 4.4: Update Cart to Handle searchResultVariation

**Files:**
- Modify: `Modules/Sources/PointOfSale/Models/Cart.swift`

**Step 1: Update createPurchasableItem**

```swift
case .searchResultVariation(let variation, _):
    return PurchasableItem(id: UUID(), item: variation, title: variation.parentProductName, subtitle: variation.name, quantity: 1)
```

**Step 2: Commit and create PR**

```bash
git add Modules/Sources/PointOfSale/Models/Cart.swift
git commit -m "$(cat <<'EOF'
Handle searchResultVariation in Cart

Adds to cart same as regular variation.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"

git push
gh pr create --title "POS FTS Search: UI Components (4/5)" --body "$(cat <<'EOF'
## Summary
- Adds searchResultVariation case to POSItem enum
- Creates SearchResultVariationCardView showing parent name + attributes
- Updates ItemListRow and Cart to handle new case

## Test plan
- [ ] Build succeeds
- [ ] Preview SearchResultVariationCardView renders correctly
- [ ] Tapping search result variation adds to cart

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

---

# PR 5: Search Strategy FTS Integration

**Estimated lines:** ~100 (excluding tests)

**Depends on:** PR 1-4

## Task 5.1: Update Search Strategy

**Files:**
- Modify: `Modules/Sources/Yosemite/PointOfSale/Items/PointOfSaleLocalSearchPurchasableItemFetchStrategy.swift`
- Modify: `Modules/Tests/YosemiteTests/PointOfSale/PointOfSaleLocalSearchPurchasableItemFetchStrategyTests.swift`

**Step 1: Add tests for FTS search**

Add to tests:

```swift
@Test("fetchProducts returns mixed products and variations from FTS")
func test_fetchProducts_returns_mixed_results() async throws {
    // Given
    try await insertProduct(makeProduct(id: 1, name: "Coffee Beans", productTypeKey: "simple"))
    try await insertProduct(makeProduct(id: 2, name: "Coffee Mug", productTypeKey: "variable"))
    try await insertVariation(makeVariation(id: 100, productID: 2))
    try await insertVariationAttribute(siteID: siteID, variationID: 100, name: "Size", option: "Large")
    try await POSSearchIndexBuilder.rebuildIndex(for: siteID, in: grdbManager.databaseConnection)

    let strategy = PointOfSaleLocalSearchPurchasableItemFetchStrategy(
        siteID: siteID,
        searchTerm: "coffee",
        grdbManager: grdbManager,
        variationsRemote: variationsRemote,
        analytics: mockAnalytics
    )

    // When
    let result = try await strategy.fetchProducts(pageNumber: 1)

    // Then
    #expect(result.items.count == 3)
    #expect(result.items.contains { if case .simpleProduct = $0 { return true } else { return false } })
    #expect(result.items.contains { if case .variableParentProduct = $0 { return true } else { return false } })
    #expect(result.items.contains { if case .searchResultVariation = $0 { return true } else { return false } })
}

private func insertVariationAttribute(siteID: Int64, variationID: Int64, name: String, option: String) async throws {
    try await grdbManager.databaseConnection.write { db in
        var attr = PersistedProductVariationAttribute(
            siteID: siteID,
            productVariationID: variationID,
            remoteAttributeID: 0,
            name: name,
            option: option
        )
        try attr.insert(db)
    }
}
```

**Step 2: Update fetchProducts implementation**

Replace in PointOfSaleLocalSearchPurchasableItemFetchStrategy:

```swift
func fetchProducts(pageNumber: Int) async throws -> PagedItems<POSItem> {
    let startTime = Date()
    let offset = (pageNumber - 1) * pageSize

    let (searchResults, totalCount) = try await grdbManager.databaseConnection.read { db -> ([POSSearchIndex], Int) in
        let results = try POSSearchIndexBuilder.search(
            siteID: siteID,
            term: searchTerm,
            limit: pageSize,
            offset: offset,
            in: db
        )
        let count = try POSSearchIndexBuilder.searchCount(siteID: siteID, term: searchTerm, in: db)
        return (results, count)
    }

    let items = try await hydrateSearchResults(searchResults)
    let hasMorePages = (pageNumber * pageSize) < totalCount

    if pageNumber == 1 {
        let milliseconds = Int(Date().timeIntervalSince(startTime) * Double(MSEC_PER_SEC))
        analytics.trackSearchLocalResultsFetchComplete(millisecondsSinceRequestSent: milliseconds,
                                                       totalItems: totalCount)
    }

    return PagedItems(items: items, hasMorePages: hasMorePages, totalItems: totalCount)
}

private func hydrateSearchResults(_ searchResults: [POSSearchIndex]) async throws -> [POSItem] {
    try await grdbManager.databaseConnection.read { db in
        try searchResults.compactMap { index -> POSItem? in
            switch index.itemType {
            case .simpleProduct:
                guard let product = try PersistedProduct.fetchOne(db, key: ["siteID": index.siteID, "id": index.itemID]) else {
                    return nil
                }
                return try .simpleProduct(product.toPOSSimpleProduct(db: db))

            case .variableProduct:
                guard let product = try PersistedProduct.fetchOne(db, key: ["siteID": index.siteID, "id": index.itemID]) else {
                    return nil
                }
                return try .variableParentProduct(product.toPOSVariableParentProduct(db: db))

            case .variation:
                guard let variation = try PersistedProductVariation.fetchOne(db, key: ["siteID": index.siteID, "id": index.itemID]),
                      let parentProductID = index.parentProductID,
                      let parentProduct = try PersistedProduct.fetchOne(db, key: ["siteID": index.siteID, "id": parentProductID]) else {
                    return nil
                }
                let posVariation = try variation.toPOSProductVariation(db: db)
                let posParentProduct = try parentProduct.toPOSVariableParentProduct(db: db)
                return .searchResultVariation(posVariation, parentProduct: posParentProduct)
            }
        }
    }
}
```

**Step 3: Run tests and commit**

```bash
git add Modules/Sources/Yosemite/PointOfSale/Items/PointOfSaleLocalSearchPurchasableItemFetchStrategy.swift Modules/Tests/YosemiteTests/PointOfSale/PointOfSaleLocalSearchPurchasableItemFetchStrategyTests.swift
git commit -m "$(cat <<'EOF'
Update search strategy to use FTS

Replaces LIKE queries with FTS5 search returning mixed product and
variation results ranked by BM25 relevance.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"

git push
gh pr create --title "POS FTS Search: Strategy Integration (5/5)" --body "$(cat <<'EOF'
## Summary
- Updates PointOfSaleLocalSearchPurchasableItemFetchStrategy to use FTS
- Returns mixed product and variation results
- Results ranked by BM25 relevance

## Test plan
- [ ] Run PointOfSaleLocalSearchPurchasableItemFetchStrategyTests
- [ ] Test search returns products and variations together
- [ ] Test relevance ranking feels correct
- [ ] Test pagination works

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

---

## Open Items (Post-Implementation)

1. **Verify migration timing** - Ensure FTS migration completes before POS modal opens
2. **Performance testing** - Test with large catalogs (1000+ products)
3. **BM25 tuning** - Verify ranking feels right with real data
