import Testing
import Yosemite
@testable import WooCommerce

@MainActor
struct BookingsTabEligibilityCheckerTests {
    @Test func checkVisibility_returns_false() async throws {
        // Given
        let site = Site.fake()
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        let checker = BookingsTabEligibilityChecker(site: site,
                                                    stores: stores,
                                                    featureFlagService: MockFeatureFlagService())

        // When
        let result = await checker.checkVisibility()

        // Then
        #expect(result == false)
    }
}
