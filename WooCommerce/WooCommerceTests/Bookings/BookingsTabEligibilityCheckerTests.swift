import Combine
import Foundation
import Testing
import WooFoundation
import Yosemite
@testable import WooCommerce

@MainActor
struct BookingsTabEligibilityCheckerTests {
    private var stores: MockStoresManager!
    private var site: Site!
    private var featureFlagService: MockFeatureFlagService!
    private var ciabEligibilityChecker: MockCIABEligibilityChecker!
    private let siteID: Int64 = 123

    init() {
        stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.updateDefaultStore(storeID: siteID)
        site = Site.fake().copy(siteID: siteID)
        featureFlagService = MockFeatureFlagService()
        ciabEligibilityChecker = MockCIABEligibilityChecker(mockedIsCurrentSiteCIAB: true, mockedCIABSites: [site])
    }

    // MARK: - `checkInitialVisibility` Tests

    @Test func checkInitialVisibility_returns_true_when_cached_tab_visibility_is_enabled() async throws {
        // Given
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        userDefaults[.ciabBookingsTabAvailable] = [siteID.description: true]
        let checker = BookingsTabEligibilityChecker(site: site,
                                                    stores: stores,
                                                    featureFlagService: featureFlagService,
                                                    ciabEligibilityChecker: ciabEligibilityChecker,
                                                    userDefaults: userDefaults)

        // When
        let result = checker.checkInitialVisibility()

        // Then
        #expect(result == true)
    }

    @Test func checkInitialVisibility_returns_false_when_cached_tab_visibility_is_disabled() async throws {
        // Given
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        userDefaults[.ciabBookingsTabAvailable] = [siteID.description: false]
        let checker = BookingsTabEligibilityChecker(site: site,
                                                    stores: stores,
                                                    featureFlagService: featureFlagService,
                                                    ciabEligibilityChecker: ciabEligibilityChecker,
                                                    userDefaults: userDefaults)

        // When
        let result = checker.checkInitialVisibility()

        // Then
        #expect(result == false)
    }

    @Test func checkInitialVisibility_returns_false_when_cached_tab_visibility_is_unavailable() async throws {
        // Given
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        let checker = BookingsTabEligibilityChecker(site: site,
                                                    stores: stores,
                                                    featureFlagService: featureFlagService,
                                                    ciabEligibilityChecker: ciabEligibilityChecker,
                                                    userDefaults: userDefaults)

        // When
        let result = checker.checkInitialVisibility()

        // Then
        #expect(result == false)
    }

    // MARK: - `checkVisibility` Tests

    @Test func checkVisibility_returns_false_when_feature_flag_is_disabled() async throws {
        // Given
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        let featureFlagService = MockFeatureFlagService(isCIABBookingsEnabled: false)
        let checker = BookingsTabEligibilityChecker(site: site,
                                                    stores: stores,
                                                    featureFlagService: featureFlagService,
                                                    ciabEligibilityChecker: ciabEligibilityChecker,
                                                    userDefaults: userDefaults)

        // When
        let result = await checker.checkVisibility()

        // Then
        #expect(result == false)
    }

    @Test func checkVisibility_returns_false_when_site_is_not_CIAB() async throws {
        // Given
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        let featureFlagService = MockFeatureFlagService(isCIABBookingsEnabled: true)
        let ciabEligibilityChecker = MockCIABEligibilityChecker(mockedIsCurrentSiteCIAB: false)
        setupStoreHasBookableProducts(hasProducts: true)
        setupStoreHasBookings(hasBookings: true)
        let checker = BookingsTabEligibilityChecker(site: site,
                                                    stores: stores,
                                                    featureFlagService: featureFlagService,
                                                    ciabEligibilityChecker: ciabEligibilityChecker,
                                                    userDefaults: userDefaults)

        // When
        let result = await checker.checkVisibility()

        // Then
        #expect(result == false)
    }

    @Test func checkVisibility_returns_false_when_store_has_no_bookable_products_and_no_bookings() async throws {
        // Given
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        let featureFlagService = MockFeatureFlagService(isCIABBookingsEnabled: true)
        setupStoreHasBookableProducts(hasProducts: false)
        setupStoreHasBookings(hasBookings: false)
        let checker = BookingsTabEligibilityChecker(site: site,
                                                    stores: stores,
                                                    featureFlagService: featureFlagService,
                                                    ciabEligibilityChecker: ciabEligibilityChecker,
                                                    userDefaults: userDefaults)

        // When
        let result = await checker.checkVisibility()

        // Then
        #expect(result == false)
    }

    @Test func checkVisibility_returns_true_when_store_has_bookable_products() async throws {
        // Given
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        let featureFlagService = MockFeatureFlagService(isCIABBookingsEnabled: true)
        setupStoreHasBookableProducts(hasProducts: true)
        setupStoreHasBookings(hasBookings: false)
        let checker = BookingsTabEligibilityChecker(site: site,
                                                    stores: stores,
                                                    featureFlagService: featureFlagService,
                                                    ciabEligibilityChecker: ciabEligibilityChecker,
                                                    userDefaults: userDefaults)

        // When
        let result = await checker.checkVisibility()

        // Then
        #expect(result == true)
    }

    @Test func checkVisibility_caches_result_when_visible() async throws {
        // Given
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        let featureFlagService = MockFeatureFlagService(isCIABBookingsEnabled: true)
        setupStoreHasBookableProducts(hasProducts: true)
        setupStoreHasBookings(hasBookings: false)
        let checker = BookingsTabEligibilityChecker(site: site,
                                                    stores: stores,
                                                    featureFlagService: featureFlagService,
                                                    ciabEligibilityChecker: ciabEligibilityChecker,
                                                    userDefaults: userDefaults)

        // When
        let result = await checker.checkVisibility()

        // Then
        #expect(result == true)
        #expect(userDefaults.loadCachedBookingsTabVisibility(siteID: siteID) == true)
    }

    @Test func checkVisibility_caches_result_when_not_visible() async throws {
        // Given
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        let featureFlagService = MockFeatureFlagService(isCIABBookingsEnabled: true)
        setupStoreHasBookableProducts(hasProducts: false)
        setupStoreHasBookings(hasBookings: false)
        let checker = BookingsTabEligibilityChecker(site: site,
                                                    stores: stores,
                                                    featureFlagService: featureFlagService,
                                                    ciabEligibilityChecker: ciabEligibilityChecker,
                                                    userDefaults: userDefaults)

        // When
        let result = await checker.checkVisibility()

        // Then
        #expect(result == false)
        #expect(userDefaults.loadCachedBookingsTabVisibility(siteID: siteID) == false)
    }

    @Test func checkVisibility_handles_bookable_products_check_failure_gracefully() async throws {
        // Given
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        let featureFlagService = MockFeatureFlagService(isCIABBookingsEnabled: true)
        setupStoreHasBookableProducts(hasProducts: false, shouldFail: true)
        setupStoreHasBookings(hasBookings: false)
        let checker = BookingsTabEligibilityChecker(site: site,
                                                    stores: stores,
                                                    featureFlagService: featureFlagService,
                                                    ciabEligibilityChecker: ciabEligibilityChecker,
                                                    userDefaults: userDefaults)

        // When
        let result = await checker.checkVisibility()

        // Then
        #expect(result == false)
    }

    @Test func checkVisibility_returns_true_when_store_has_bookings_but_no_bookable_products() async throws {
        // Given
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        let featureFlagService = MockFeatureFlagService(isCIABBookingsEnabled: true)
        setupStoreHasBookableProducts(hasProducts: false)
        setupStoreHasBookings(hasBookings: true)
        let checker = BookingsTabEligibilityChecker(site: site,
                                                    stores: stores,
                                                    featureFlagService: featureFlagService,
                                                    ciabEligibilityChecker: ciabEligibilityChecker,
                                                    userDefaults: userDefaults)

        // When
        let result = await checker.checkVisibility()

        // Then
        #expect(result == true)
    }

    @Test func checkVisibility_returns_true_when_store_has_both_bookings_and_bookable_products() async throws {
        // Given
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        let featureFlagService = MockFeatureFlagService(isCIABBookingsEnabled: true)
        setupStoreHasBookableProducts(hasProducts: true)
        setupStoreHasBookings(hasBookings: true)
        let checker = BookingsTabEligibilityChecker(site: site,
                                                    stores: stores,
                                                    featureFlagService: featureFlagService,
                                                    ciabEligibilityChecker: ciabEligibilityChecker,
                                                    userDefaults: userDefaults)

        // When
        let result = await checker.checkVisibility()

        // Then
        #expect(result == true)
    }

    @Test func checkVisibility_handles_bookings_check_failure_gracefully() async throws {
        // Given
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        let featureFlagService = MockFeatureFlagService(isCIABBookingsEnabled: true)
        setupStoreHasBookableProducts(hasProducts: false)
        setupStoreHasBookings(hasBookings: false, shouldFail: true)
        let checker = BookingsTabEligibilityChecker(site: site,
                                                    stores: stores,
                                                    featureFlagService: featureFlagService,
                                                    ciabEligibilityChecker: ciabEligibilityChecker,
                                                    userDefaults: userDefaults)

        // When
        let result = await checker.checkVisibility()

        // Then
        #expect(result == false)
    }

    @Test func checkVisibility_handles_both_checks_failure_gracefully() async throws {
        // Given
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        let featureFlagService = MockFeatureFlagService(isCIABBookingsEnabled: true)
        setupStoreHasBookableProducts(hasProducts: false, shouldFail: true)
        setupStoreHasBookings(hasBookings: false, shouldFail: true)
        let checker = BookingsTabEligibilityChecker(site: site,
                                                    stores: stores,
                                                    featureFlagService: featureFlagService,
                                                    ciabEligibilityChecker: ciabEligibilityChecker,
                                                    userDefaults: userDefaults)

        // When
        let result = await checker.checkVisibility()

        // Then
        #expect(result == false)
    }

    // MARK: - POS Bookings Interaction Tests

    @Test func checkInitialVisibility_returns_false_when_pos_bookings_enabled_and_pos_tab_visible() async throws {
        // Given
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        userDefaults[.ciabBookingsTabAvailable] = [siteID.description: true]
        let featureFlagService = MockFeatureFlagService()
        featureFlagService.isFeatureFlagEnabledReturnValue[.pointOfSaleBookings] = true
        let checker = BookingsTabEligibilityChecker(site: site,
                                                    stores: stores,
                                                    featureFlagService: featureFlagService,
                                                    ciabEligibilityChecker: ciabEligibilityChecker,
                                                    userDefaults: userDefaults,
                                                    isPOSTabVisible: { true })

        // When
        let result = checker.checkInitialVisibility()

        // Then
        #expect(result == false)
    }

    @Test func checkInitialVisibility_returns_cached_value_when_pos_bookings_not_enabled() async throws {
        // Given
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        userDefaults[.ciabBookingsTabAvailable] = [siteID.description: true]
        let featureFlagService = MockFeatureFlagService()
        featureFlagService.isFeatureFlagEnabledReturnValue[.pointOfSaleBookings] = false
        let checker = BookingsTabEligibilityChecker(site: site,
                                                    stores: stores,
                                                    featureFlagService: featureFlagService,
                                                    ciabEligibilityChecker: ciabEligibilityChecker,
                                                    userDefaults: userDefaults,
                                                    isPOSTabVisible: { true })

        // When
        let result = checker.checkInitialVisibility()

        // Then
        #expect(result == true)
    }

    @Test func checkInitialVisibility_returns_cached_value_when_pos_tab_not_visible() async throws {
        // Given
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        userDefaults[.ciabBookingsTabAvailable] = [siteID.description: true]
        let featureFlagService = MockFeatureFlagService()
        featureFlagService.isFeatureFlagEnabledReturnValue[.pointOfSaleBookings] = true
        let checker = BookingsTabEligibilityChecker(site: site,
                                                    stores: stores,
                                                    featureFlagService: featureFlagService,
                                                    ciabEligibilityChecker: ciabEligibilityChecker,
                                                    userDefaults: userDefaults,
                                                    isPOSTabVisible: { false })

        // When
        let result = checker.checkInitialVisibility()

        // Then
        #expect(result == true)
    }

    @Test func checkVisibility_returns_false_when_pos_bookings_enabled_and_pos_tab_visible() async throws {
        // Given
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        let featureFlagService = MockFeatureFlagService(isCIABBookingsEnabled: true)
        featureFlagService.isFeatureFlagEnabledReturnValue[.pointOfSaleBookings] = true
        setupStoreHasBookableProducts(hasProducts: true)
        let checker = BookingsTabEligibilityChecker(site: site,
                                                    stores: stores,
                                                    featureFlagService: featureFlagService,
                                                    ciabEligibilityChecker: ciabEligibilityChecker,
                                                    userDefaults: userDefaults,
                                                    isPOSTabVisible: { true })

        // When
        let result = await checker.checkVisibility()

        // Then
        #expect(result == false)
    }

    @Test func checkVisibility_returns_true_when_pos_bookings_enabled_but_pos_tab_not_visible() async throws {
        // Given
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        let featureFlagService = MockFeatureFlagService(isCIABBookingsEnabled: true)
        featureFlagService.isFeatureFlagEnabledReturnValue[.pointOfSaleBookings] = true
        setupStoreHasBookableProducts(hasProducts: true)
        let checker = BookingsTabEligibilityChecker(site: site,
                                                    stores: stores,
                                                    featureFlagService: featureFlagService,
                                                    ciabEligibilityChecker: ciabEligibilityChecker,
                                                    userDefaults: userDefaults,
                                                    isPOSTabVisible: { false })

        // When
        let result = await checker.checkVisibility()

        // Then
        #expect(result == true)
    }

    // MARK: - UserDefaults Extension Tests

    @Test func userDefaults_loadCachedBookingsTabVisibility_returns_false_when_no_cache() async throws {
        // Given
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!

        // When
        let result = userDefaults.loadCachedBookingsTabVisibility(siteID: siteID)

        // Then
        #expect(result == false)
    }

    @Test func userDefaults_loadCachedBookingsTabVisibility_returns_cached_value() async throws {
        // Given
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        userDefaults[.ciabBookingsTabAvailable] = [siteID.description: true]

        // When
        let result = userDefaults.loadCachedBookingsTabVisibility(siteID: siteID)

        // Then
        #expect(result == true)
    }

    @Test func userDefaults_cacheBookingsTabVisibility_stores_value_correctly() async throws {
        // Given
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!

        // When
        userDefaults.cacheBookingsTabVisibility(siteID: siteID, isVisible: true)

        // Then
        #expect(userDefaults[.ciabBookingsTabAvailable] == [siteID.description: true])
    }

    @Test func userDefaults_handles_multiple_sites() async throws {
        // Given
        let siteID2: Int64 = 456
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!

        // When
        userDefaults[.ciabBookingsTabAvailable] = [
            siteID.description: true,
            siteID2.description: false
        ]

        // Then
        #expect(userDefaults.loadCachedBookingsTabVisibility(siteID: siteID) == true)
        #expect(userDefaults.loadCachedBookingsTabVisibility(siteID: siteID2) == false)
    }
}

// MARK: - Private Helpers

private extension BookingsTabEligibilityCheckerTests {

    func setupStoreHasBookableProducts(hasProducts: Bool, shouldFail: Bool = false) {
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case .checkIfStoreHasProducts(_, _, let type, let completion):
                if type == .booking {
                    if shouldFail {
                        completion(.failure(NSError(domain: "test", code: 500)))
                    } else {
                        completion(.success(hasProducts))
                    }
                }
            default:
                break
            }
        }
    }

    func setupStoreHasBookings(hasBookings: Bool, shouldFail: Bool = false) {
        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            switch action {
            case .checkIfStoreHasBookings(_, let completion):
                if shouldFail {
                    completion(.failure(NSError(domain: "test", code: 500)))
                } else {
                    completion(.success(hasBookings))
                }
            default:
                break
            }
        }
    }
}
