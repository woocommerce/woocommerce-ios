import Foundation
import Testing
import Yosemite
@testable import WooCommerce

@MainActor
struct BookingsTabEligibilityCheckerTests {
    private var stores: MockStoresManager!
    private var site: Site!
    private let siteID: Int64 = 123

    init() {
        stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.updateDefaultStore(storeID: siteID)
        site = Site.fake().copy(siteID: siteID)
    }

    @Test func checkVisibility_returns_false_when_store_has_no_bookable_products_and_no_bookings() async throws {
        // Given
        setupStoreHasBookableProducts(hasProducts: false)
        setupStoreHasBookings(hasBookings: false)
        let checker = BookingsTabEligibilityChecker(site: site, stores: stores)

        // When
        let result = await checker.checkVisibility()

        // Then
        #expect(result == false)
    }

    @Test func checkVisibility_returns_true_when_store_has_bookable_products() async throws {
        // Given
        setupStoreHasBookableProducts(hasProducts: true)
        setupStoreHasBookings(hasBookings: false)
        let checker = BookingsTabEligibilityChecker(site: site, stores: stores)

        // When
        let result = await checker.checkVisibility()

        // Then
        #expect(result == true)
    }

    @Test func checkVisibility_handles_bookable_products_check_failure_gracefully() async throws {
        // Given
        setupStoreHasBookableProducts(hasProducts: false, shouldFail: true)
        setupStoreHasBookings(hasBookings: false)
        let checker = BookingsTabEligibilityChecker(site: site, stores: stores)

        // When
        let result = await checker.checkVisibility()

        // Then
        #expect(result == false)
    }

    @Test func checkVisibility_returns_true_when_store_has_bookings_but_no_bookable_products() async throws {
        // Given
        setupStoreHasBookableProducts(hasProducts: false)
        setupStoreHasBookings(hasBookings: true)
        let checker = BookingsTabEligibilityChecker(site: site, stores: stores)

        // When
        let result = await checker.checkVisibility()

        // Then
        #expect(result == true)
    }

    @Test func checkVisibility_returns_true_when_store_has_both_bookings_and_bookable_products() async throws {
        // Given
        setupStoreHasBookableProducts(hasProducts: true)
        setupStoreHasBookings(hasBookings: true)
        let checker = BookingsTabEligibilityChecker(site: site, stores: stores)

        // When
        let result = await checker.checkVisibility()

        // Then
        #expect(result == true)
    }

    @Test func checkVisibility_handles_bookings_check_failure_gracefully() async throws {
        // Given
        setupStoreHasBookableProducts(hasProducts: false)
        setupStoreHasBookings(hasBookings: false, shouldFail: true)
        let checker = BookingsTabEligibilityChecker(site: site, stores: stores)

        // When
        let result = await checker.checkVisibility()

        // Then
        #expect(result == false)
    }

    @Test func checkVisibility_handles_both_checks_failure_gracefully() async throws {
        // Given
        setupStoreHasBookableProducts(hasProducts: false, shouldFail: true)
        setupStoreHasBookings(hasBookings: false, shouldFail: true)
        let checker = BookingsTabEligibilityChecker(site: site, stores: stores)

        // When
        let result = await checker.checkVisibility()

        // Then
        #expect(result == false)
    }
}

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
