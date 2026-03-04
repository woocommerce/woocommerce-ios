import Testing
import Foundation
@testable import PointOfSale
@testable import Yosemite

struct POSSettingsLocalCatalogViewModelTests {
    private let sampleSiteID: Int64 = 12345
    private let sut: POSSettingsLocalCatalogViewModel
    private let catalogSettingsService: MockPOSCatalogSettingsService
    private let catalogSyncCoordinator: MockPOSCatalogSyncCoordinator
    private let siteSettings: MockSiteSpecificAppSettingsStoreMethods

    init() {
        self.catalogSettingsService = MockPOSCatalogSettingsService()
        self.catalogSyncCoordinator = MockPOSCatalogSyncCoordinator()
        self.siteSettings = MockSiteSpecificAppSettingsStoreMethods()
        self.siteSettings.currentSiteID = sampleSiteID
        self.sut = POSSettingsLocalCatalogViewModel(
            siteID: sampleSiteID,
            catalogSettingsService: catalogSettingsService,
            catalogSyncCoordinator: catalogSyncCoordinator,
            siteSettings: siteSettings
        )
    }

    // MARK: - Initialization

    @Test func view_model_initializes_with_correct_properties() async throws {
        // Then
        #expect(sut.catalogSize == "")
        #expect(sut.lastFullSyncDate == "")
        #expect(sut.lastIncrementalSyncDate == "")
        #expect(sut.isLoading == false)
        #expect(sut.isRefreshingCatalog == false)
        #expect(sut.catalogRefreshError == nil)
    }

    // MARK: - `loadCatalogData` Tests

    @Test func loadCatalogData_sets_catalog_size_and_sync_dates_on_success() async throws {
        // Given
        catalogSettingsService.catalogInfoResult = .success(POSCatalogInfo(
            productCount: 150,
            variationCount: 75,
            lastFullSyncDate: Date(timeIntervalSinceNow: -3600), // 1 hour ago
            lastIncrementalSyncDate: Date(timeIntervalSinceNow: -1800) // 30 minutes ago
        ))

        // When
        await sut.loadCatalogData()

        // Then
        #expect(sut.catalogSize == "150 products and 75 variations")
        #expect(sut.lastFullSyncDate.contains("ago"))
        #expect(sut.lastIncrementalSyncDate.contains("ago"))
        #expect(sut.isLoading == false)
    }

    @Test func loadCatalogData_sets_all_fields_to_unavailable_when_loadCatalogInfo_returns_error() async throws {
        // Given
        catalogSettingsService.catalogInfoResult = .failure(MockError.loadError)

        // When
        await sut.loadCatalogData()

        // Then
        #expect(sut.catalogSize == "Catalog size unavailable")
        #expect(sut.lastFullSyncDate == "Update date unavailable")
        #expect(sut.lastIncrementalSyncDate == "Update date unavailable")
    }

    @Test func loadCatalogData_sets_sync_dates_to_placeholder_when_sync_dates_are_nil() async throws {
        // Given
        catalogSettingsService.catalogInfoResult = .success(POSCatalogInfo(
            productCount: 100,
            variationCount: 50,
            lastFullSyncDate: nil,
            lastIncrementalSyncDate: nil
        ))

        // When
        await sut.loadCatalogData()

        // Then
        #expect(sut.catalogSize == "100 products and 50 variations")
        #expect(sut.lastFullSyncDate == "Not updated")
        #expect(sut.lastIncrementalSyncDate == "Not updated")
    }


    @Test func loadCatalogData_sets_loading_state_correctly() async throws {
        // Given
        catalogSettingsService.catalogInfoResult = .success(POSCatalogInfo(
            productCount: 0,
            variationCount: 0,
            lastFullSyncDate: nil,
            lastIncrementalSyncDate: nil
        ))

        await confirmation() { confirmation in
            catalogSettingsService.onLoadCatalogInfoCalled = {
                // At the time loadCatalogInfo is called, loading is set to true
                #expect(sut.isLoading == true)
                confirmation()
            }

            // When
            await sut.loadCatalogData()
        }

        // Then
        #expect(sut.isLoading == false)
    }

    // MARK: - `refreshCatalog` Tests

    @Test func refreshCatalog_performs_full_sync_and_reloads_data_when_sync_succeeds() async throws {
        // Given
        catalogSettingsService.catalogInfoResult = .success(POSCatalogInfo(
            productCount: 200,
            variationCount: 100,
            lastFullSyncDate: Date(),
            lastIncrementalSyncDate: Date()
        ))

        // When
        await sut.refreshCatalog()

        // Then
        #expect(catalogSyncCoordinator.performFullSyncInvocationCount == 1)
        #expect(catalogSyncCoordinator.performFullSyncSiteID == sampleSiteID)
        #expect(sut.catalogSize == "200 products and 100 variations")
        #expect(sut.isRefreshingCatalog == false)
    }

    @Test func refreshCatalog_sets_refreshing_state_correctly() async throws {
        // Given
        catalogSettingsService.catalogInfoResult = .success(POSCatalogInfo(
            productCount: 0,
            variationCount: 0,
            lastFullSyncDate: nil,
            lastIncrementalSyncDate: nil
        ))

        await confirmation() { confirmation in
            catalogSyncCoordinator.onPerformFullSyncCalled = {
                // At the time performFullSyncCalled is called, isRefreshingCatalog is set to true
                #expect(sut.isRefreshingCatalog == true)
                confirmation()
            }

            // When
            await sut.refreshCatalog()
        }

        // Then
        #expect(sut.isRefreshingCatalog == false)
    }

    @Test func refreshCatalog_does_not_update_catalog_size_when_sync_fails() async throws {
        // Given
        catalogSettingsService.catalogInfoResult = .success(POSCatalogInfo(
            productCount: 50,
            variationCount: 25,
            lastFullSyncDate: nil,
            lastIncrementalSyncDate: nil
        ))
        catalogSyncCoordinator.performFullSyncResult = .failure(MockError.syncError)

        // When
        await sut.refreshCatalog()

        // Then
        #expect(catalogSyncCoordinator.performFullSyncInvocationCount == 1)
        #expect(sut.catalogSize != "50 products, 25 variations") // `loadCatalogInfo` should not be invoked
        #expect(sut.isRefreshingCatalog == false)
    }

    @Test func refreshCatalog_sets_refresh_error_state_when_sync_fails() async throws {
        // Given
        catalogSettingsService.catalogInfoResult = .success(POSCatalogInfo(
            productCount: 50,
            variationCount: 25,
            lastFullSyncDate: nil,
            lastIncrementalSyncDate: nil
        ))
        catalogSyncCoordinator.performFullSyncResult = .failure(MockError.syncError)

        // When
        await sut.refreshCatalog()

        // Then
        let catalogRefreshError = try #require(sut.catalogRefreshError)
        #expect(catalogRefreshError.errorState.errorType == .refreshCatalogSyncError)
    }

    // MARK: - Test Concurrent Operations

    @Test func concurrent_loadCatalogData_and_refreshCatalog_operations_work_correctly() async throws {
        // Given
        catalogSettingsService.catalogInfoResult = .success(POSCatalogInfo(
            productCount: 100,
            variationCount: 50,
            lastFullSyncDate: Date(),
            lastIncrementalSyncDate: Date()
        ))

        // When
        let loadTask = Task {
            await sut.loadCatalogData()
        }
        let refreshTask = Task {
            await sut.refreshCatalog()
        }

        await loadTask.value
        await refreshTask.value

        // Then
        #expect(sut.catalogSize == "100 products and 50 variations")
        #expect(sut.isLoading == false)
        #expect(sut.isRefreshingCatalog == false)
        #expect(catalogSyncCoordinator.performFullSyncInvocationCount == 1)
    }

    // MARK: - allowFullSyncOnCellular Tests

    @Test func allowFullSyncOnCellular_returns_default_value_from_site_settings() async throws {
        // Given
        siteSettings.mockPOSLocalCatalogCellularDataAllowed = false

        // When
        let isAllowed = sut.allowFullSyncOnCellular

        // Then
        #expect(isAllowed == false)
        #expect(siteSettings.getPOSLocalCatalogCellularDataAllowedCalled == true)
    }

    @Test func allowFullSyncOnCellular_setter_updates_site_settings() async throws {
        // When
        sut.allowFullSyncOnCellular = true

        // Then
        #expect(siteSettings.setPOSLocalCatalogCellularDataAllowedCalled == true)
        #expect(siteSettings.mockPOSLocalCatalogCellularDataAllowed == true)
    }

    @Test func allowFullSyncOnCellular_getter_and_setter_work_as_two_way_binding() async throws {
        // Given - Initially false
        siteSettings.mockPOSLocalCatalogCellularDataAllowed = false
        #expect(sut.allowFullSyncOnCellular == false)

        // When - Set to true
        sut.allowFullSyncOnCellular = true

        // Then - Value is persisted and can be retrieved
        #expect(siteSettings.mockPOSLocalCatalogCellularDataAllowed == true)
        #expect(sut.allowFullSyncOnCellular == true)

        // When - Set to false
        sut.allowFullSyncOnCellular = false

        // Then - Value is persisted and can be retrieved
        #expect(siteSettings.mockPOSLocalCatalogCellularDataAllowed == false)
        #expect(sut.allowFullSyncOnCellular == false)
    }
}

private enum MockError: Error {
    case loadError
    case syncError
}
