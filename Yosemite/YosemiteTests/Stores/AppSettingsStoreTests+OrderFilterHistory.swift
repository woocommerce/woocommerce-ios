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
        let siteID: Int64 = 123
        let filter = createMockFilter(siteID: siteID)
        let subject = AppSettingsStore(dispatcher: dispatcher!,
                                       storageManager: storageManager!,
                                       fileStorage: fileStorage!,
                                       generalAppSettings: generalAppSettings!)

        // Confidence check
        await #expect(throws: AppSettingsStoreErrors.noOrderFilterHistory) {
            _ = try await withCheckedThrowingContinuation { continuation in
                subject.onAction(AppSettingsAction.loadOrderFilterHistory(siteID: siteID) { result in
                    continuation.resume(with: result)
                })
            }
        }

        // When
        let error = await withCheckedContinuation { continuation in
            subject.onAction(AppSettingsAction.upsertOrderFilterHistory(filter: filter, onCompletion: { error in
                continuation.resume(returning: error)
            }))
        }
        try #require(error == nil)

        // Then
        let resultAfterWritingAction: [StoredOrderSettings.Setting] = try await withCheckedThrowingContinuation { continuation in
            subject.onAction(AppSettingsAction.loadOrderFilterHistory(siteID: siteID) { result in
                continuation.resume(with: result)
            })
        }
        #expect(resultAfterWritingAction == [filter])
    }

}

private extension AppSettingsStoreTests_OrderFilterHistory {
    func createMockFilter(siteID: Int64) -> StoredOrderSettings.Setting {
        let orderStatuses: [OrderStatusEnum] = [.pending, .completed]
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
}
