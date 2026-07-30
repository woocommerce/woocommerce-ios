import Testing
import Foundation
import Yosemite
import Experiments
@testable import WooCommerce

/// Covers the eligibility table for the POS refund flow decision: feature flag, cached
/// server-availability verdicts, and the WooCommerce version gate (11.1.0).
@MainActor
@Suite(.timeLimit(.minutes(5)))
struct POSRefundFlowResolverTests {

    private let siteID: Int64 = 123

    @Test func resolveFlow_when_flag_disabled_then_local() {
        // Given
        let sut = makeSUT(flagEnabled: false)

        // Then
        #expect(sut.resolveFlow(siteID: siteID) == .localComputed)
    }

    @Test func resolveFlow_when_site_cached_unavailable_then_local_even_on_a_supported_version() {
        // Given a probe already returned `rest_no_route` for the site
        let cache = ServerRefundAvailabilityCache()
        cache.markUnavailable(siteID: siteID)
        let sut = makeSUT(cachedWooVersion: "11.2.0", cache: cache)

        // Then
        #expect(sut.resolveFlow(siteID: siteID) == .localComputed)
    }

    @Test func resolveFlow_when_wc_version_below_minimum_then_local() {
        // Given the last release before the endpoints shipped
        let sut = makeSUT(cachedWooVersion: "11.0.9")

        // Then
        #expect(sut.resolveFlow(siteID: siteID) == .localComputed)
    }

    @Test func resolveFlow_when_wc_version_at_minimum_then_server() {
        // Given
        let sut = makeSUT(cachedWooVersion: "11.1.0")

        // Then
        #expect(sut.resolveFlow(siteID: siteID) == .serverComputed)
    }

    @Test func resolveFlow_when_wc_version_above_minimum_then_server() {
        // Given
        let sut = makeSUT(cachedWooVersion: "11.2.1")

        // Then
        #expect(sut.resolveFlow(siteID: siteID) == .serverComputed)
    }

    @Test func resolveFlow_when_wc_version_is_prerelease_of_minimum_then_server() {
        // Given a beta of the minimum version (11.1.0-beta1 must not read as below 11.1.0)
        let sut = makeSUT(cachedWooVersion: "11.1.0-beta1")

        // Then
        #expect(sut.resolveFlow(siteID: siteID) == .serverComputed)
    }

    @Test func resolveFlow_when_wc_version_unknown_then_server_so_the_probe_decides() {
        // Given a missing cached version isn't conclusive
        let sut = makeSUT(cachedWooVersion: nil)

        // Then
        #expect(sut.resolveFlow(siteID: siteID) == .serverComputed)
    }

    @Test func resolveFlow_when_site_cached_available_then_server_despite_a_stale_version_hint() {
        // Given a server-confirmed site and a (stale) below-minimum version string
        let cache = ServerRefundAvailabilityCache()
        cache.markAvailable(siteID: siteID)
        let sut = makeSUT(cachedWooVersion: "11.0.9", cache: cache)

        // Then
        #expect(sut.resolveFlow(siteID: siteID) == .serverComputed)
    }
}

private extension POSRefundFlowResolverTests {

    func makeSUT(flagEnabled: Bool = true,
                 cachedWooVersion: String? = "11.1.0",
                 cache: ServerRefundAvailabilityCache? = nil) -> POSRefundFlowResolver {
        // Resolved in the (main-actor) test body rather than as a default argument: the cache's
        // initializer is main-actor-isolated, and default arguments are evaluated nonisolated.
        let cache = cache ?? ServerRefundAvailabilityCache()
        let session = SessionManager.testingInstance
        session.cachedWooCommerceVersion = cachedWooVersion
        let stores = MockStoresManager(sessionManager: session)
        let flags = MockFeatureFlagService()
        flags.isFeatureFlagEnabledReturnValue = [.posRefundsV4: flagEnabled]
        return POSRefundFlowResolver(stores: stores,
                                     featureFlagService: flags,
                                     availabilityCache: cache,
                                     minimumWooVersion: "11.1.0")
    }
}
