import Testing
import Foundation
import Yosemite
import Experiments
import enum NetworkingCore.DotcomError
import enum NetworkingCore.NetworkError
@testable import WooCommerce

@MainActor
@Suite(.timeLimit(.minutes(5)))
struct POSV4RefundPreviewUseCaseTests {

    private let siteID: Int64 = 123
    private let orderID: Int64 = 456

    // MARK: - Gating without a network call

    @Test func previewRefund_when_flag_disabled_then_falls_back_without_dispatch() async {
        // Given
        let (sut, service, _) = makeSUT(flagEnabled: false)

        // When
        let result = await sut.previewRefund(siteID: siteID, orderID: orderID, lineItems: [lineItem()])

        // Then
        #expect(result == .fallbackToLocal)
        #expect(service.previewRefundCallCount == 0)
    }

    @Test func previewRefund_when_site_cached_unavailable_then_falls_back_without_dispatch() async {
        // Given
        let cache = V4RefundAvailabilityCache()
        cache.markV4Unavailable(siteID: siteID)
        let (sut, service, _) = makeSUT(cache: cache)

        // When
        let result = await sut.previewRefund(siteID: siteID, orderID: orderID, lineItems: [lineItem()])

        // Then
        #expect(result == .fallbackToLocal)
        #expect(service.previewRefundCallCount == 0)
    }

    @Test func previewRefund_when_wc_version_below_minimum_then_falls_back_without_writing_cache() async {
        // Given
        let cache = V4RefundAvailabilityCache()
        let (sut, service, stores) = makeSUT(cachedWooVersion: "10.8.0", cache: cache, previewResult: .success(preview()))

        // When
        let result = await sut.previewRefund(siteID: siteID, orderID: orderID, lineItems: [lineItem()])

        // Then the version hint skips the probe but never carries a probe's permanence.
        #expect(result == .fallbackToLocal)
        #expect(service.previewRefundCallCount == 0)
        #expect(cache.isV4Available(siteID: siteID) == nil)

        // When the cached version is corrected, the next call probes normally.
        (stores.sessionManager as? SessionManager)?.cachedWooCommerceVersion = "10.9.0"
        let secondResult = await sut.previewRefund(siteID: siteID, orderID: orderID, lineItems: [lineItem()])

        // Then
        #expect(secondResult == .serverCalculated(preview()))
        #expect(cache.isV4Available(siteID: siteID) == true)
    }

    @Test func previewRefund_when_site_cached_available_then_stale_version_hint_is_ignored() async {
        // Given a server-confirmed site and a (stale) below-minimum version string
        let cache = V4RefundAvailabilityCache()
        cache.markV4Available(siteID: siteID)
        let (sut, _, _) = makeSUT(cachedWooVersion: "10.8.0", cache: cache, previewResult: .success(preview()))

        // When
        let result = await sut.previewRefund(siteID: siteID, orderID: orderID, lineItems: [lineItem()])

        // Then the probe runs and the confirmed availability is not downgraded.
        #expect(result == .serverCalculated(preview()))
        #expect(cache.isV4Available(siteID: siteID) == true)
    }

    @Test func previewRefund_when_wc_version_is_prerelease_of_minimum_then_probes() async {
        // Given a beta of the minimum version (10.9.0-beta1 must not read as below 10.9.0)
        let cache = V4RefundAvailabilityCache()
        let (sut, _, _) = makeSUT(cachedWooVersion: "10.9.0-beta1", cache: cache, previewResult: .success(preview()))

        // When
        let result = await sut.previewRefund(siteID: siteID, orderID: orderID, lineItems: [lineItem()])

        // Then
        #expect(result == .serverCalculated(preview()))
        #expect(cache.isV4Available(siteID: siteID) == true)
    }

    @Test func previewRefund_when_wc_version_unknown_then_probes_instead_of_falling_back() async {
        // Given a missing cached version isn't conclusive, so the probe decides.
        let cache = V4RefundAvailabilityCache()
        let (sut, _, _) = makeSUT(cachedWooVersion: nil, cache: cache, previewResult: .success(preview()))

        // When
        let result = await sut.previewRefund(siteID: siteID, orderID: orderID, lineItems: [lineItem()])

        // Then
        #expect(result == .serverCalculated(preview()))
        #expect(cache.isV4Available(siteID: siteID) == true)
    }

    @Test func previewRefund_when_no_line_items_then_falls_back_without_dispatch() async {
        // Given
        let (sut, service, _) = makeSUT()

        // When
        let result = await sut.previewRefund(siteID: siteID, orderID: orderID, lineItems: [])

        // Then
        #expect(result == .fallbackToLocal)
        #expect(service.previewRefundCallCount == 0)
    }

    // MARK: - Probe outcomes

    @Test func previewRefund_when_server_returns_preview_then_returns_it_and_marks_available() async {
        // Given
        let cache = V4RefundAvailabilityCache()
        let (sut, _, _) = makeSUT(cache: cache, previewResult: .success(preview()))

        // When
        let result = await sut.previewRefund(siteID: siteID, orderID: orderID, lineItems: [lineItem()])

        // Then
        #expect(result == .serverCalculated(preview()))
        #expect(cache.isV4Available(siteID: siteID) == true)
    }

    @Test func previewRefund_when_dotcom_rest_no_route_then_marks_unavailable_and_falls_back() async {
        // Given
        let cache = V4RefundAvailabilityCache()
        let (sut, _, _) = makeSUT(cache: cache, previewResult: .failure(DotcomError.noRestRoute()))

        // When
        let result = await sut.previewRefund(siteID: siteID, orderID: orderID, lineItems: [lineItem()])

        // Then
        #expect(result == .fallbackToLocal)
        #expect(cache.isV4Available(siteID: siteID) == false)
    }

    @Test func previewRefund_when_network_404_rest_no_route_then_marks_unavailable_and_falls_back() async {
        // Given
        let cache = V4RefundAvailabilityCache()
        let response = Data(#"{"code":"rest_no_route"}"#.utf8)
        let (sut, _, _) = makeSUT(cache: cache, previewResult: .failure(NetworkError.notFound(response: response)))

        // When
        let result = await sut.previewRefund(siteID: siteID, orderID: orderID, lineItems: [lineItem()])

        // Then
        #expect(result == .fallbackToLocal)
        #expect(cache.isV4Available(siteID: siteID) == false)
    }

    @Test func previewRefund_when_404_without_rest_no_route_then_returns_error_without_marking_unavailable() async {
        // Given a genuine missing-resource 404 (not a missing route)
        let cache = V4RefundAvailabilityCache()
        let response = Data(#"{"code":"woocommerce_rest_shop_order_invalid_id"}"#.utf8)
        let (sut, _, _) = makeSUT(cache: cache, previewResult: .failure(NetworkError.notFound(response: response)))

        // When
        let result = await sut.previewRefund(siteID: siteID, orderID: orderID, lineItems: [lineItem()])

        // Then v4 stays enabled for the session; only `rest_no_route` may disable it.
        #expect(result == .error)
        #expect(cache.isV4Available(siteID: siteID) == nil)
    }

    @Test func previewRefund_when_other_error_then_returns_error_without_marking_unavailable() async {
        // Given
        let cache = V4RefundAvailabilityCache()
        let (sut, _, _) = makeSUT(cache: cache, previewResult: .failure(NetworkError.timeout()))

        // When
        let result = await sut.previewRefund(siteID: siteID, orderID: orderID, lineItems: [lineItem()])

        // Then
        #expect(result == .error)
        #expect(cache.isV4Available(siteID: siteID) == nil)
    }

    // MARK: - Seeding availability from the REST index routes

    @Test func seedAvailability_when_index_lists_v4_refund_routes_then_marks_available() async {
        // Given
        let cache = V4RefundAvailabilityCache()
        let loader = MockSiteAPILoader(result: .success(siteAPI(routes: ["/wc/v3/orders", "/wc/v4/refunds", "/wc/v4/refunds/preview"])))
        let (sut, _, _) = makeSUT(cache: cache, siteAPILoader: loader)

        // When
        await sut.seedAvailabilityFromSiteRoutesIfNeeded(siteID: siteID)

        // Then
        #expect(cache.isV4Available(siteID: siteID) == true)
        #expect(loader.callCount == 1)
    }

    @Test func seedAvailability_when_route_present_then_stale_version_hint_no_longer_blocks_preview() async {
        // Given a stale below-minimum version that would gate the probe off
        let cache = V4RefundAvailabilityCache()
        let loader = MockSiteAPILoader(result: .success(siteAPI(routes: ["/wc/v4/refunds/preview"])))
        let (sut, _, _) = makeSUT(cachedWooVersion: "10.8.0",
                                  cache: cache,
                                  previewResult: .success(preview()),
                                  siteAPILoader: loader)

        // When the routes are seeded before the preview
        await sut.seedAvailabilityFromSiteRoutesIfNeeded(siteID: siteID)
        let result = await sut.previewRefund(siteID: siteID, orderID: orderID, lineItems: [lineItem()])

        // Then the seeded availability overrides the stale version hint
        #expect(result == .serverCalculated(preview()))
    }

    @Test func seedAvailability_when_routes_missing_then_cache_stays_unresolved() async {
        // Given an index without the v4 refund routes (flag off server-side, or a filtered index)
        let cache = V4RefundAvailabilityCache()
        let loader = MockSiteAPILoader(result: .success(siteAPI(routes: ["/wc/v3/orders", "/wc/v3/orders/(?P<order_id>[\\d]+)/refunds"])))
        let (sut, _, _) = makeSUT(cache: cache, siteAPILoader: loader)

        // When
        await sut.seedAvailabilityFromSiteRoutesIfNeeded(siteID: siteID)

        // Then absence is inconclusive: the probe stays the only negative signal
        #expect(cache.isV4Available(siteID: siteID) == nil)
    }

    @Test func seedAvailability_when_index_fetch_fails_then_cache_stays_unresolved() async {
        // Given
        let cache = V4RefundAvailabilityCache()
        let loader = MockSiteAPILoader(result: .failure(NetworkError.timeout()))
        let (sut, _, _) = makeSUT(cache: cache, siteAPILoader: loader)

        // When
        await sut.seedAvailabilityFromSiteRoutesIfNeeded(siteID: siteID)

        // Then
        #expect(cache.isV4Available(siteID: siteID) == nil)
    }

    @Test func seedAvailability_when_availability_already_cached_then_skips_the_fetch() async {
        // Given
        let cache = V4RefundAvailabilityCache()
        cache.markV4Unavailable(siteID: siteID)
        let loader = MockSiteAPILoader(result: .success(siteAPI(routes: ["/wc/v4/refunds"])))
        let (sut, _, _) = makeSUT(cache: cache, siteAPILoader: loader)

        // When
        await sut.seedAvailabilityFromSiteRoutesIfNeeded(siteID: siteID)

        // Then the cached (probe-derived) verdict is never overridden or re-checked
        #expect(loader.callCount == 0)
        #expect(cache.isV4Available(siteID: siteID) == false)
    }

    @Test func seedAvailability_when_flag_disabled_then_skips_the_fetch() async {
        // Given
        let loader = MockSiteAPILoader(result: .success(siteAPI(routes: ["/wc/v4/refunds"])))
        let (sut, _, _) = makeSUT(flagEnabled: false, siteAPILoader: loader)

        // When
        await sut.seedAvailabilityFromSiteRoutesIfNeeded(siteID: siteID)

        // Then
        #expect(loader.callCount == 0)
    }

    @Test func seedAvailability_is_attempted_at_most_once_per_site() async {
        // Given an index without the v4 routes, so the cache stays nil after the first attempt
        let cache = V4RefundAvailabilityCache()
        let loader = MockSiteAPILoader(result: .success(siteAPI(routes: ["/wc/v3/orders"])))
        let (sut, _, _) = makeSUT(cache: cache, siteAPILoader: loader)

        // When seeding twice concurrently and once more afterwards
        async let first: Void = sut.seedAvailabilityFromSiteRoutesIfNeeded(siteID: siteID)
        async let second: Void = sut.seedAvailabilityFromSiteRoutesIfNeeded(siteID: siteID)
        _ = await (first, second)
        await sut.seedAvailabilityFromSiteRoutesIfNeeded(siteID: siteID)

        // Then only one index fetch ever happens
        #expect(loader.callCount == 1)
    }
}

private extension POSV4RefundPreviewUseCaseTests {

    @MainActor
    final class MockSiteAPILoader {
        private let result: Swift.Result<SiteAPI, Error>
        private(set) var callCount = 0

        init(result: Swift.Result<SiteAPI, Error>) {
            self.result = result
        }

        func load(siteID: Int64) async throws -> SiteAPI {
            callCount += 1
            return try result.get()
        }
    }

    func makeSUT(flagEnabled: Bool = true,
                 cachedWooVersion: String? = "10.9.0",
                 cache: V4RefundAvailabilityCache? = nil,
                 previewResult: Swift.Result<RefundPreview, Error>? = nil,
                 siteAPILoader: MockSiteAPILoader? = nil)
    -> (POSV4RefundPreviewUseCase, MockRefundService, MockStoresManager) {
        // Resolved in the (main-actor) test body rather than as a default argument: the cache's
        // initializer is main-actor-isolated, and default arguments are evaluated nonisolated.
        let cache = cache ?? V4RefundAvailabilityCache()
        let loader = siteAPILoader ?? MockSiteAPILoader(result: .failure(MockRefundService.MockError.notStubbed))
        let session = SessionManager.testingInstance
        session.cachedWooCommerceVersion = cachedWooVersion
        let stores = MockStoresManager(sessionManager: session)
        let service = MockRefundService()
        service.previewRefundResult = previewResult
        let flags = MockFeatureFlagService()
        flags.isFeatureFlagEnabledReturnValue = [.posRefundsV4: flagEnabled]
        let sut = POSV4RefundPreviewUseCase(refundService: service,
                                            stores: stores,
                                            featureFlagService: flags,
                                            availabilityCache: cache,
                                            minimumWooVersion: "10.9.0",
                                            siteAPILoader: { try await loader.load(siteID: $0) })
        return (sut, service, stores)
    }

    func lineItem() -> RefundV4LineItem {
        .quantityBased(lineItemID: 10, quantity: 1)
    }

    func preview() -> RefundPreview {
        RefundPreview(subtotal: 27, tax: 2.43, total: 29.43, maxRefundable: 59, breakdown: .fake())
    }

    func siteAPI(routes: [String]) -> SiteAPI {
        SiteAPI(siteID: siteID, namespaces: [], applicationPasswordAvailable: false, routes: routes)
    }
}
