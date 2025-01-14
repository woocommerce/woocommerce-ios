import Testing
@testable import Yosemite
@testable import Storage

struct AppSettingsStoreTests_OrderFilterHistory {

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
    @Test func loadOrderFilterHistory_returns_correct_results_after_upserting() async throws {
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
        await #expect(throws: AppSettingsStoreErrors.noOrderFilterHistory) {
            _ = try await withCheckedThrowingContinuation { continuation in
                subject.onAction(AppSettingsAction.loadOrderFilterHistory(siteID: siteID1) { result in
                    continuation.resume(with: result)
                })
            }
        }

        // When inserting two filters for two sites
        try await insertMockFilter(filter: filter1, using: subject)
        try await insertMockFilter(filter: filter2, using: subject)

        // Then
        let resultAfterWritingAction = try await withCheckedThrowingContinuation { continuation in
            subject.onAction(AppSettingsAction.loadOrderFilterHistory(siteID: siteID1) { result in
                continuation.resume(with: result)
            })
        }
        #expect(resultAfterWritingAction == [filter1])
    }

    @MainActor
    @Test func loadOrderFilterHistory_returns_correct_results_after_removing_filter() async throws {
        // Given
        let siteID1: Int64 = 123
        let filter1 = createMockFilter(siteID: siteID1, orderStatuses: [.pending])
        let filter2 = createMockFilter(siteID: siteID1, orderStatuses: [.completed])

        let subject = AppSettingsStore(dispatcher: dispatcher!,
                                       storageManager: storageManager!,
                                       fileStorage: fileStorage!,
                                       generalAppSettings: generalAppSettings!)

        try await insertMockFilter(filter: filter1, using: subject)
        try await insertMockFilter(filter: filter2, using: subject)

        // Confidence check
        let initialResult = try await withCheckedThrowingContinuation { continuation in
            subject.onAction(AppSettingsAction.loadOrderFilterHistory(siteID: siteID1) { result in
                continuation.resume(with: result)
            })
        }
        #expect(initialResult == [filter2, filter1])

        // When
        let error = await withCheckedContinuation { continuation in
            subject.onAction(AppSettingsAction.removeFromOrderFilterHistory(filter: filter1, onCompletion: { error in
                continuation.resume(returning: error)
            }))
        }
        try #require(error == nil)

        // Then
        let resultAfterRemoval = try await withCheckedThrowingContinuation { continuation in
            subject.onAction(AppSettingsAction.loadOrderFilterHistory(siteID: siteID1) { result in
                continuation.resume(with: result)
            })
        }
        #expect(resultAfterRemoval == [filter2])
    }

    @MainActor
    @Test func resetOrderFilterHistory_clears_all_persisted_history() async throws {
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
            subject.onAction(AppSettingsAction.resetOrderFilterHistory(siteID: siteID1, onCompletion: { error in
                continuation.resume(returning: error)
            }))
        }
        try #require(error == nil)

        // Then
        let site1Filters = try await withCheckedThrowingContinuation { continuation in
            subject.onAction(AppSettingsAction.loadOrderFilterHistory(siteID: siteID1) { result in
                continuation.resume(with: result)
            })
        }
        #expect(site1Filters == [])

        let site2Filters = try await withCheckedThrowingContinuation { continuation in
            subject.onAction(AppSettingsAction.loadOrderFilterHistory(siteID: siteID2) { result in
                continuation.resume(with: result)
            })
        }
        #expect(site2Filters == [filter2])
    }
}

private extension AppSettingsStoreTests_OrderFilterHistory {
    func createMockFilter(siteID: Int64,
                          orderStatuses: [OrderStatusEnum] = [.pending, .completed]) -> StoredOrderSettings.Setting {
        let orderStatuses = orderStatuses
        let startDate = Date().yearStart
        let endDate = Date().yearEnd
        let dateRange = OrderDateRangeFilter(filter: .custom, startDate: startDate, endDate: endDate)
        let productFilter = FilterOrdersByProduct(id: 1, name: "Sample product")
        let customerFilter = CustomerFilter(customer: Customer.fake().copy(customerID: 1))
        return StoredOrderSettings.Setting(siteID: siteID,
                                           orderStatusesFilter: orderStatuses,
                                           dateRangeFilter: dateRange,
                                           productFilter: productFilter,
                                           customerFilter: customerFilter)
    }

    func insertMockFilter(filter: StoredOrderSettings.Setting, using store: AppSettingsStore) async throws {
        let error = await withCheckedContinuation { continuation in
            store.onAction(AppSettingsAction.upsertOrderFilterHistory(filter: filter, onCompletion: { error in
                continuation.resume(returning: error)
            }))
        }
        try #require(error == nil)
    }
}
