import Testing
import YosemiteTestHelpers
@testable import Yosemite
@testable import Storage
@testable import Networking

struct AppSettingsStoreTests_BookingFilters {

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
    @Test func loadBookingFilters_returns_error_when_no_filters_are_saved() async throws {
        // Given
        let siteID: Int64 = 123
        let subject = AppSettingsStore(dispatcher: dispatcher,
                                       storageManager: storageManager,
                                       fileStorage: fileStorage,
                                       generalAppSettings: generalAppSettings)

        // When/Then
        await #expect(throws: AppSettingsStoreErrors.noBookingFilters) {
            _ = try await withCheckedThrowingContinuation { continuation in
                subject.onAction(AppSettingsAction.loadBookingFilters(siteID: siteID) { result in
                    continuation.resume(with: result)
                })
            }
        }
    }

    @MainActor
    @Test func loadBookingFilters_returns_correct_values_after_being_set() async throws {
        // Given
        let siteID: Int64 = 134

        let filters = StoredBookingFilters.Filters(
            teamMembers: [BookingTeamMemberFilter(resourceID: 100, name: "Team Member 1")],
            products: [BookingProductFilter(productID: 1, name: "Product 1")],
            attendanceStatus: .attended,
            customers: [BookingCustomerFilter(customerID: 10, name: "Customer 1")],
            dateRange: nil
        )

        let subject = AppSettingsStore(dispatcher: dispatcher,
                                       storageManager: storageManager,
                                       fileStorage: fileStorage,
                                       generalAppSettings: generalAppSettings)

        // When
        let upsertError = await withCheckedContinuation { continuation in
            let writeAction = AppSettingsAction.upsertBookingFilters(siteID: siteID,
                                                                     filters: filters) { error in
                continuation.resume(returning: error)
            }
            subject.onAction(writeAction)
        }
        try #require(upsertError == nil)

        // Then
        let result = try await withCheckedThrowingContinuation { continuation in
            let readAction = AppSettingsAction.loadBookingFilters(siteID: siteID) { result in
                continuation.resume(with: result)
            }
            subject.onAction(readAction)
        }

        #expect(result == filters)
    }

    @MainActor
    @Test func loadBookingFilters_returns_correct_values_for_multiple_sites() async throws {
        // Given
        let siteID1: Int64 = 134
        let siteID2: Int64 = 268

        let filters1 = StoredBookingFilters.Filters(
            teamMembers: [BookingTeamMemberFilter(resourceID: 100, name: "Team Member 1")],
            products: [BookingProductFilter(productID: 1, name: "Product 1")],
            attendanceStatus: .attended,
            customers: [BookingCustomerFilter(customerID: 10, name: "Customer 1")],
            dateRange: nil
        )

        let filters2 = StoredBookingFilters.Filters(
            teamMembers: [BookingTeamMemberFilter(resourceID: 200, name: "Team Member 2")],
            products: [BookingProductFilter(productID: 2, name: "Product 2")],
            attendanceStatus: .unattended,
            customers: [],
            dateRange: nil
        )

        let subject = AppSettingsStore(dispatcher: dispatcher,
                                       storageManager: storageManager,
                                       fileStorage: fileStorage,
                                       generalAppSettings: generalAppSettings)

        // When
        let upsertError1 = await withCheckedContinuation { continuation in
            let writeAction = AppSettingsAction.upsertBookingFilters(siteID: siteID1,
                                                                     filters: filters1) { error in
                continuation.resume(returning: error)
            }
            subject.onAction(writeAction)
        }
        try #require(upsertError1 == nil)

        let upsertError2 = await withCheckedContinuation { continuation in
            let writeAction = AppSettingsAction.upsertBookingFilters(siteID: siteID2,
                                                                     filters: filters2) { error in
                continuation.resume(returning: error)
            }
            subject.onAction(writeAction)
        }
        try #require(upsertError2 == nil)

        // Then
        let result1 = try await withCheckedThrowingContinuation { continuation in
            let readAction = AppSettingsAction.loadBookingFilters(siteID: siteID1) { result in
                continuation.resume(with: result)
            }
            subject.onAction(readAction)
        }
        #expect(result1 == filters1)

        let result2 = try await withCheckedThrowingContinuation { continuation in
            let readAction = AppSettingsAction.loadBookingFilters(siteID: siteID2) { result in
                continuation.resume(with: result)
            }
            subject.onAction(readAction)
        }
        #expect(result2 == filters2)
    }

    @MainActor
    @Test func upsertBookingFilters_updates_existing_filters_for_same_site() async throws {
        // Given
        let siteID: Int64 = 134

        let initialFilters = StoredBookingFilters.Filters(
            teamMembers: [BookingTeamMemberFilter(resourceID: 100, name: "Team Member 1")],
            products: [BookingProductFilter(productID: 1, name: "Product 1")],
            attendanceStatus: nil,
            customers: [BookingCustomerFilter(customerID: 10, name: "Customer 1")],
            dateRange: nil
        )

        let updatedFilters = StoredBookingFilters.Filters(
            teamMembers: [],
            products: [],
            attendanceStatus: .attended,
            customers: [BookingCustomerFilter(customerID: 20, name: "Customer 2")],
            dateRange: nil
        )

        let subject = AppSettingsStore(dispatcher: dispatcher,
                                       storageManager: storageManager,
                                       fileStorage: fileStorage,
                                       generalAppSettings: generalAppSettings)

        // When - first insert
        let firstError = await withCheckedContinuation { continuation in
            let writeAction = AppSettingsAction.upsertBookingFilters(siteID: siteID,
                                                                     filters: initialFilters) { error in
                continuation.resume(returning: error)
            }
            subject.onAction(writeAction)
        }
        try #require(firstError == nil)

        // When - update with new filters
        let secondError = await withCheckedContinuation { continuation in
            let writeAction = AppSettingsAction.upsertBookingFilters(siteID: siteID,
                                                                     filters: updatedFilters) { error in
                continuation.resume(returning: error)
            }
            subject.onAction(writeAction)
        }
        try #require(secondError == nil)

        // Then
        let result = try await withCheckedThrowingContinuation { continuation in
            let readAction = AppSettingsAction.loadBookingFilters(siteID: siteID) { result in
                continuation.resume(with: result)
            }
            subject.onAction(readAction)
        }

        #expect(result == updatedFilters)
    }

    @MainActor
    @Test func resetBookingFilters_clears_all_filters() async throws {
        // Given
        let siteID: Int64 = 134

        let filters = StoredBookingFilters.Filters(
            teamMembers: [BookingTeamMemberFilter(resourceID: 100, name: "Team Member 1")],
            products: [],
            attendanceStatus: .attended,
            customers: [],
            dateRange: nil
        )

        let subject = AppSettingsStore(dispatcher: dispatcher,
                                       storageManager: storageManager,
                                       fileStorage: fileStorage,
                                       generalAppSettings: generalAppSettings)

        // First save some filters
        let upsertError = await withCheckedContinuation { continuation in
            let writeAction = AppSettingsAction.upsertBookingFilters(siteID: siteID,
                                                                     filters: filters) { error in
                continuation.resume(returning: error)
            }
            subject.onAction(writeAction)
        }
        try #require(upsertError == nil)

        // Verify filters are saved
        _ = try await withCheckedThrowingContinuation { continuation in
            let readAction = AppSettingsAction.loadBookingFilters(siteID: siteID) { result in
                continuation.resume(with: result)
            }
            subject.onAction(readAction)
        }

        // When
        let resetAction = AppSettingsAction.resetBookingFilters
        subject.onAction(resetAction)

        // Then
        await #expect(throws: AppSettingsStoreErrors.noBookingFilters) {
            _ = try await withCheckedThrowingContinuation { continuation in
                subject.onAction(AppSettingsAction.loadBookingFilters(siteID: siteID) { result in
                    continuation.resume(with: result)
                })
            }
        }
    }
}
