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
}

private extension POSV4RefundPreviewUseCaseTests {

    func makeSUT(flagEnabled: Bool = true,
                 cachedWooVersion: String? = "10.9.0",
                 cache: V4RefundAvailabilityCache? = nil,
                 previewResult: Swift.Result<RefundPreview, Error>? = nil)
    -> (POSV4RefundPreviewUseCase, MockRefundService, MockStoresManager) {
        // Resolved in the (main-actor) test body rather than as a default argument: the cache's
        // initializer is main-actor-isolated, and default arguments are evaluated nonisolated.
        let cache = cache ?? V4RefundAvailabilityCache()
        let session = SessionManager.testingInstance
        session.cachedWooCommerceVersion = cachedWooVersion
        let stores = MockStoresManager(sessionManager: session)
        let service = MockRefundService()
        service.previewRefundResult = previewResult
        let flags = MockFeatureFlagService()
        flags.isFeatureFlagEnabledReturnValue = [.posServerCalculatedRefunds: flagEnabled]
        let sut = POSV4RefundPreviewUseCase(refundService: service,
                                            stores: stores,
                                            featureFlagService: flags,
                                            availabilityCache: cache,
                                            minimumWooVersion: "10.9.0")
        return (sut, service, stores)
    }

    func lineItem() -> RefundV4LineItem {
        .quantityBased(lineItemID: 10, quantity: 1)
    }

    func preview() -> RefundPreview {
        RefundPreview(subtotal: 27, tax: 2.43, total: 29.43, maxRefundable: 59, breakdown: .fake())
    }
}
