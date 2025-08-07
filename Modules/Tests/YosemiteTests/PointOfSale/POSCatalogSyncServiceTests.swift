import Testing
@testable import Networking
@testable import Yosemite
@testable import Storage

struct POSCatalogSyncServiceTests {
    private var sut: POSCatalogSyncService!
    private var mockNetwork: MockNetwork!
    private var mockStorageManager: MockStorageManager!
    private var mockDispatcher: Dispatcher!

    @MainActor
    init() {
        mockNetwork = MockNetwork()
        mockStorageManager = MockStorageManager()
        mockDispatcher = Dispatcher()
        sut = POSCatalogSyncService(
            siteID: 123,
            network: mockNetwork,
            storageManager: mockStorageManager,
            dispatcher: mockDispatcher
        )
    }

    // MARK: - Success Tests

    @Test func syncCatalog_with_valid_json_succeeds() async throws {
        // Given
        mockNetwork.simulateResponse(requestUrlSuffix: "pos-catalog.json", filename: "pos-catalog-valid")

        // When & Then
        try await sut.syncCatalog()
    }

    @Test func syncCatalog_with_mixed_products_and_variations_processes_correctly() async throws {
        // Given
        mockNetwork.simulateResponse(requestUrlSuffix: "pos-catalog.json", filename: "pos-catalog-mixed")

        // When
        try await sut.syncCatalog()

        // Then - just verify it completed without error
    }

    @Test func syncCatalog_with_large_dataset_processes_in_batches() async throws {
        // Given
        mockNetwork.simulateResponse(requestUrlSuffix: "pos-catalog.json", filename: "pos-catalog-large")

        // When
        try await sut.syncCatalog()

        // Then - just verify it completed without error
    }

    @Test func syncCatalog_with_empty_json_array_succeeds() async throws {
        // Given
        mockNetwork.simulateResponse(requestUrlSuffix: "pos-catalog.json", filename: "pos-catalog-empty")

        // When & Then
        try await sut.syncCatalog()
    }

    // MARK: - Error Tests

    @Test func syncCatalog_with_network_error_throws_correct_error() async throws {
        // Given
        mockNetwork.simulateError(requestUrlSuffix: "pos-catalog.json", error: NetworkError.notFound())

        // When & Then
        await #expect(throws: NetworkError.notFound(response: nil)) {
            try await sut.syncCatalog()
        }
    }

    @Test func syncCatalog_with_invalid_json_throws_invalidData_error() async throws {
        // Given
        mockNetwork.simulateResponse(requestUrlSuffix: "pos-catalog.json", filename: "pos-catalog-invalid")

        // When & Then
        await #expect(throws: POSCatalogSyncError.invalidData) {
            try await sut.syncCatalog()
        }
    }
}
