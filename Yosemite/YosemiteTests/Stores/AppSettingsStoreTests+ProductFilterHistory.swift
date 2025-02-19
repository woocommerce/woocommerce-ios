import Testing
@testable import Yosemite
@testable import Storage

struct AppSettingsStoreTests_ProductFilterHistory {

    /// Mock Dispatcher!
    ///
    private var dispatcher: Dispatcher!

    /// Mock Storage: InMemory
    ///
    private var storageManager: MockStorageManager!

    /// Mock File Storage: Load data in memory
    ///
    private var fileStorage: MockInMemoryStorage!

    /// Mock General Settings Storage: Load data in memory
    ///
    private var generalAppSettings: GeneralAppSettingsStorage!

    init() {
        dispatcher = Dispatcher()
        storageManager = MockStorageManager()
        fileStorage = MockInMemoryStorage()
        generalAppSettings = GeneralAppSettingsStorage(fileStorage: fileStorage)
    }

    @MainActor
    @Test func loadProductFilterHistory_returns_correct_results_after_upserting() async throws {
        // Given
        let siteID1: Int64 = 123
        let filter1 = createMockFilter(siteID: siteID1)

        let siteID2: Int64 = 34
        let filter2 = createMockFilter(siteID: siteID2)

        let subject = AppSettingsStore(dispatcher: dispatcher!,
                                       storageManager: storageManager!,
                                       fileStorage: fileStorage!,
                                       generalAppSettings: generalAppSettings!)

        // Confidence check
        await #expect(throws: AppSettingsStoreErrors.noProductFilterHistory) {
            _ = try await withCheckedThrowingContinuation { continuation in
                subject.onAction(AppSettingsAction.loadProductFilterHistory(siteID: siteID1) { result in
                    continuation.resume(with: result)
                })
            }
        }

        // When inserting two filters for two sites
        try await insertMockFilter(filter: filter1, using: subject)
        try await insertMockFilter(filter: filter2, using: subject)

        // Then
        let resultAfterWritingAction = try await withCheckedThrowingContinuation { continuation in
            subject.onAction(AppSettingsAction.loadProductFilterHistory(siteID: siteID1) { result in
                continuation.resume(with: result)
            })
        }
        #expect(resultAfterWritingAction == [filter1])
    }

    @MainActor
    @Test func loadProductFilterHistory_returns_correct_results_after_removing_filter() async throws {
        // Given
        let siteID1: Int64 = 123
        let filter1 = createMockFilter(siteID: siteID1, stockStatusFilter: nil)
        let filter2 = createMockFilter(siteID: siteID1, stockStatusFilter: .inStock)

        let subject = AppSettingsStore(dispatcher: dispatcher!,
                                       storageManager: storageManager!,
                                       fileStorage: fileStorage!,
                                       generalAppSettings: generalAppSettings!)

        try await insertMockFilter(filter: filter1, using: subject)
        try await insertMockFilter(filter: filter2, using: subject)

        // Confidence check
        let initialResult = try await withCheckedThrowingContinuation { continuation in
            subject.onAction(AppSettingsAction.loadProductFilterHistory(siteID: siteID1) { result in
                continuation.resume(with: result)
            })
        }
        #expect(initialResult == [filter2, filter1])

        // When
        let error = await withCheckedContinuation { continuation in
            subject.onAction(AppSettingsAction.removeFromProductFilterHistory(filter: filter1, onCompletion: { error in
                continuation.resume(returning: error)
            }))
        }
        try #require(error == nil)

        // Then
        let resultAfterRemoval = try await withCheckedThrowingContinuation { continuation in
            subject.onAction(AppSettingsAction.loadProductFilterHistory(siteID: siteID1) { result in
                continuation.resume(with: result)
            })
        }
        #expect(resultAfterRemoval == [filter2])
    }

    @MainActor
    @Test func resetProductFilterHistory_clears_all_persisted_history() async throws {
        // Given
        let siteID1: Int64 = 123
        let filter1 = createMockFilter(siteID: siteID1)

        let siteID2: Int64 = 34
        let filter2 = createMockFilter(siteID: siteID2)

        let subject = AppSettingsStore(dispatcher: dispatcher!,
                                       storageManager: storageManager!,
                                       fileStorage: fileStorage!,
                                       generalAppSettings: generalAppSettings!)

        try await insertMockFilter(filter: filter1, using: subject)
        try await insertMockFilter(filter: filter2, using: subject)

        // When
        let error = await withCheckedContinuation { continuation in
            subject.onAction(AppSettingsAction.resetProductFilterHistory(siteID: siteID1, onCompletion: { error in
                continuation.resume(returning: error)
            }))
        }
        try #require(error == nil)

        // Then
        let site1Filters = try await withCheckedThrowingContinuation { continuation in
            subject.onAction(AppSettingsAction.loadProductFilterHistory(siteID: siteID1) { result in
                continuation.resume(with: result)
            })
        }
        #expect(site1Filters == [])

        let site2Filters = try await withCheckedThrowingContinuation { continuation in
            subject.onAction(AppSettingsAction.loadProductFilterHistory(siteID: siteID2) { result in
                continuation.resume(with: result)
            })
        }
        #expect(site2Filters == [filter2])
    }
}

private extension AppSettingsStoreTests_ProductFilterHistory {
    func createMockFilter(siteID: Int64,
                          stockStatusFilter: ProductStockStatus? = .outOfStock) -> StoredProductSettings.Setting {
        StoredProductSettings.Setting(siteID: siteID,
                                      sort: ProductsSortOrder.dateAscending.rawValue,
                                      stockStatusFilter: stockStatusFilter,
                                      productStatusFilter: .pending,
                                      productTypeFilter: .simple,
                                      productCategoryFilter: ProductCategory(categoryID: 0, siteID: 0, parentID: 0, name: "", slug: ""),
                                      favoriteProduct: true)
    }

    func insertMockFilter(filter: StoredProductSettings.Setting, using store: AppSettingsStore) async throws {
        let error = await withCheckedContinuation { continuation in
            store.onAction(AppSettingsAction.upsertProductFilterHistory(filter: filter, onCompletion: { error in
                continuation.resume(returning: error)
            }))
        }
        try #require(error == nil)
    }
}
