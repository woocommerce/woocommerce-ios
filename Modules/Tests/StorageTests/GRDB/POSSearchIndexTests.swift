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
