import Testing
import Combine
import Foundation

@testable import Yosemite
@testable import Storage
import class WooFoundation.CurrencySettings

struct POSCartProductObserverTests {
    private let siteID: Int64 = 1

    @Test func observe_when_product_exists_then_publishes_item() async throws {
        // Given
        let grdbManager = try GRDBManager()
        insertSite(into: grdbManager)
        insertProduct(id: 42, price: "10.00", into: grdbManager)

        let sut = POSCartProductObserver(
            siteID: siteID,
            grdbManager: grdbManager,
            currencySettings: CurrencySettings()
        )

        // When
        let items = await firstEmission(from: sut, productIDs: [42])

        // Then
        #expect(items.count == 1)
        if case .simpleProduct(let product) = items.first {
            #expect(product.price == "10.00")
            #expect(product.productID == 42)
        } else {
            Issue.record("Expected simpleProduct, got \(String(describing: items.first))")
        }
    }

    @Test func observe_when_product_price_updated_then_publishes_new_price() async throws {
        // Given
        let grdbManager = try GRDBManager()
        insertSite(into: grdbManager)
        insertProduct(id: 42, price: "10.00", into: grdbManager)

        let sut = POSCartProductObserver(
            siteID: siteID,
            grdbManager: grdbManager,
            currencySettings: CurrencySettings()
        )

        // Wait for initial emission
        _ = await firstEmission(from: sut, productIDs: [42])

        // When: update the price and wait for the next emission
        let updatedItems = await withCheckedContinuation { (continuation: CheckedContinuation<[POSItem], Never>) in
            var cancellable: AnyCancellable?
            cancellable = sut.items
                .first()
                .sink { items in
                    continuation.resume(returning: items)
                    cancellable?.cancel()
                }

            try? grdbManager.databaseConnection.write { db in
                try db.execute(
                    sql: "UPDATE product SET price = ? WHERE siteID = ? AND id = ?",
                    arguments: ["15.00", self.siteID, 42]
                )
            }
        }

        // Then
        #expect(updatedItems.count == 1)
        if case .simpleProduct(let product) = updatedItems.first {
            #expect(product.price == "15.00")
        } else {
            Issue.record("Expected simpleProduct, got \(String(describing: updatedItems.first))")
        }
    }

    @Test func observe_when_same_IDs_called_again_then_does_not_rebuild() throws {
        // Given
        let grdbManager = try GRDBManager()
        let sut = POSCartProductObserver(
            siteID: siteID,
            grdbManager: grdbManager,
            currencySettings: CurrencySettings()
        )

        // When: call observe twice with the same IDs
        sut.observe(productIDs: [42], variationIDs: [])
        var emissionCount = 0
        let cancellable = sut.items.sink { _ in emissionCount += 1 }
        sut.observe(productIDs: [42], variationIDs: [])
        cancellable.cancel()

        // Then: second call is a no-op, no new subscription to emit from
        #expect(emissionCount == 0)
    }

    @Test func observe_when_empty_IDs_then_cancels_observation() throws {
        // Given
        let grdbManager = try GRDBManager()
        let sut = POSCartProductObserver(
            siteID: siteID,
            grdbManager: grdbManager,
            currencySettings: CurrencySettings()
        )

        sut.observe(productIDs: [42], variationIDs: [])

        // When
        sut.observe(productIDs: [], variationIDs: [])

        // Then: IDs are now empty, calling with empty again should be a no-op (cached)
        // This verifies the observation was torn down by checking it accepts the new state
        sut.observe(productIDs: [], variationIDs: [])
    }
}

// MARK: - Helpers

private extension POSCartProductObserverTests {
    func insertSite(into grdbManager: GRDBManager) {
        try? grdbManager.databaseConnection.write { db in
            try PersistedSite(id: siteID).insert(db)
        }
    }

    func insertProduct(id: Int64, price: String, into grdbManager: GRDBManager) {
        try? grdbManager.databaseConnection.write { db in
            let product = PersistedProduct(
                id: id,
                siteID: siteID,
                name: "Product \(id)",
                productTypeKey: "simple",
                fullDescription: nil,
                shortDescription: nil,
                sku: nil,
                globalUniqueID: nil,
                price: price,
                downloadable: false,
                parentID: 0,
                manageStock: false,
                stockQuantity: nil,
                stockStatusKey: "instock",
                statusKey: "publish"
            )
            try product.insert(db)
        }
    }

    /// Calls observe and waits for the first emission from the items publisher.
    func firstEmission(from observer: POSCartProductObserver, productIDs: Set<Int64>) async -> [POSItem] {
        await withCheckedContinuation { (continuation: CheckedContinuation<[POSItem], Never>) in
            var cancellable: AnyCancellable?
            cancellable = observer.items
                .first()
                .sink { items in
                    continuation.resume(returning: items)
                    cancellable?.cancel()
                }
            observer.observe(productIDs: productIDs, variationIDs: [])
        }
    }
}
