import Testing
import Foundation
import Observation
@testable import PointOfSale
@testable import Yosemite

@MainActor
@Suite(.timeLimit(.minutes(5)))
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
        #expect(sut.catalogSize.isEmpty)
        #expect(sut.lastFullSyncDate.isEmpty)
        #expect(sut.lastIncrementalSyncDate.isEmpty)
        #expect(sut.isLoading == false)
        #expect(sut.isRefreshingCatalog == false)
        #expect(sut.catalogRefreshProgress == nil)
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

    @Test func refreshCatalog_when_sync_already_in_progress_does_not_set_refresh_error() async throws {
        // Given
        catalogSyncCoordinator.performFullSyncResult = .failure(POSCatalogSyncError.syncAlreadyInProgress(siteID: sampleSiteID))

        // When
        await sut.refreshCatalog()

        // Then
        #expect(sut.catalogRefreshError == nil)
    }

    @Test func refreshCatalog_when_sync_already_in_progress_keeps_refreshing_state() async throws {
        // Given
        catalogSyncCoordinator.performFullSyncResult = .failure(POSCatalogSyncError.syncAlreadyInProgress(siteID: sampleSiteID))

        // When
        await sut.refreshCatalog()

        // Then
        #expect(sut.isRefreshingCatalog == true)
    }

    @Test func refreshCatalog_when_request_cancelled_does_not_set_refresh_error() async throws {
        // Given
        catalogSyncCoordinator.performFullSyncResult = .failure(POSCatalogSyncError.requestCancelled)

        // When
        await sut.refreshCatalog()

        // Then
        #expect(sut.catalogRefreshError == nil)
        #expect(sut.isRefreshingCatalog == false)
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

    @Test func test_setAllowFullSyncOnCellular_when_approved_then_notifies_observers() async {
        // Given
        let handler = POSManagerOverrideHandler(session: MockPOSAccessSession(currentStaff: POSLocalRole.cashier.staff))

        await confirmation { changed in
            withObservationTracking {
                _ = sut.allowFullSyncOnCellular
            } onChange: {
                changed()
            }

            // When
            sut.setAllowFullSyncOnCellular(true, approvalHandler: handler)
            #expect(await handler.submit(pin: "1234"))
        }

        // Then
        #expect(sut.allowFullSyncOnCellular)
    }

    @Test(arguments: [true, false])
    func test_setAllowFullSyncOnCellular_when_operator_has_capability_then_updates_without_approval(_ allowed: Bool) {
        // Given
        siteSettings.mockPOSLocalCatalogCellularDataAllowed = !allowed
        let session = MockPOSAccessSession(currentStaff: POSStaff(displayName: "Staff", capabilities: [.manageStoreSettings]))
        let handler = POSManagerOverrideHandler(session: session)

        // When
        sut.setAllowFullSyncOnCellular(allowed, approvalHandler: handler)

        // Then
        #expect(sut.allowFullSyncOnCellular == allowed)
        #expect(handler.request == nil)
    }

    @Test(arguments: [true, false])
    func test_setAllowFullSyncOnCellular_when_cashier_cancels_then_preserves_setting(_ allowed: Bool) {
        // Given
        siteSettings.mockPOSLocalCatalogCellularDataAllowed = !allowed
        let handler = POSManagerOverrideHandler(session: MockPOSAccessSession(currentStaff: POSLocalRole.cashier.staff))

        // When
        sut.setAllowFullSyncOnCellular(allowed, approvalHandler: handler)

        // Then
        #expect(handler.request?.capability == .manageStoreSettings)
        #expect(sut.allowFullSyncOnCellular == !allowed)
        handler.cancel()
        #expect(sut.allowFullSyncOnCellular == !allowed)
        #expect(!siteSettings.setPOSLocalCatalogCellularDataAllowedCalled)
    }

    @Test(arguments: [true, false])
    func test_setAllowFullSyncOnCellular_when_approved_then_changes_once_and_keeps_cashier_session(_ allowed: Bool) async {
        // Given
        siteSettings.mockPOSLocalCatalogCellularDataAllowed = !allowed
        let session = MockPOSAccessSession(currentStaff: POSLocalRole.cashier.staff)
        let handler = POSManagerOverrideHandler(session: session)
        sut.setAllowFullSyncOnCellular(allowed, approvalHandler: handler)

        // When
        #expect(await handler.submit(pin: "1234"))

        // Then
        #expect(sut.allowFullSyncOnCellular == allowed)
        #expect(session.managerApprovalCapabilities == [.manageStoreSettings])
        #expect(session.currentStaff == POSLocalRole.cashier.staff)
        #expect(!session.allows(.manageStoreSettings))
        sut.setAllowFullSyncOnCellular(!allowed, approvalHandler: handler)
        #expect(handler.request?.capability == .manageStoreSettings)
        #expect(sut.allowFullSyncOnCellular == allowed)
        handler.cancel()
    }

    @Test func test_setAllowFullSyncOnCellular_when_pin_is_rejected_then_preserves_setting() async {
        // Given
        let session = MockPOSAccessSession(currentStaff: POSLocalRole.cashier.staff, managerApprovalResult: .failure(.invalidPIN))
        let handler = POSManagerOverrideHandler(session: session)
        sut.setAllowFullSyncOnCellular(true, approvalHandler: handler)

        // When
        #expect(await handler.submit(pin: "1234") == false)

        // Then
        #expect(!sut.allowFullSyncOnCellular)
        #expect(!siteSettings.setPOSLocalCatalogCellularDataAllowedCalled)
        #expect(handler.request?.capability == .manageStoreSettings)
        handler.cancel()
    }

    @Test func test_setAllowFullSyncOnCellular_when_session_changes_during_approval_then_preserves_setting() async {
        // Given
        let session = MockPOSAccessSession(currentStaff: POSLocalRole.cashier.staff)
        let handler = POSManagerOverrideHandler(session: session)
        session.onManagerApproval = { session.endSession() }
        sut.setAllowFullSyncOnCellular(true, approvalHandler: handler)

        // When
        _ = await handler.submit(pin: "1234")

        // Then
        #expect(!sut.allowFullSyncOnCellular)
        #expect(!siteSettings.setPOSLocalCatalogCellularDataAllowedCalled)
        handler.cancel()
    }

    @Test func test_setAllowFullSyncOnCellular_when_protection_is_off_then_updates_without_approval() {
        // Given
        let handler = POSManagerOverrideHandler(session: UnrestrictedPOSAccessSession())

        // When
        sut.setAllowFullSyncOnCellular(true, approvalHandler: handler)

        // Then
        #expect(sut.allowFullSyncOnCellular)
        #expect(handler.request == nil)
    }

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
