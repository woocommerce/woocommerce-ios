import Testing
import Foundation
import Yosemite
import Experiments
import enum NetworkingCore.DotcomError
import enum NetworkingCore.NetworkError
@testable import WooCommerce

@MainActor
@Suite(.timeLimit(.minutes(5)))
struct POSServerRefundPreviewUseCaseTests {

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
        let cache = ServerRefundAvailabilityCache()
        cache.markUnavailable(siteID: siteID)
        let (sut, service, _) = makeSUT(cache: cache)

        // When
        let result = await sut.previewRefund(siteID: siteID, orderID: orderID, lineItems: [lineItem()])

        // Then
        #expect(result == .fallbackToLocal)
        #expect(service.previewRefundCallCount == 0)
    }

    @Test func previewRefund_when_wc_version_below_minimum_then_falls_back_without_writing_cache() async {
        // Given
        let cache = ServerRefundAvailabilityCache()
        let (sut, service, stores) = makeSUT(cachedWooVersion: Versions.belowMinimum, cache: cache, previewResult: .success(preview()))

        // When
        let result = await sut.previewRefund(siteID: siteID, orderID: orderID, lineItems: [lineItem()])

        // Then the version hint skips the probe but never carries a probe's permanence.
        #expect(result == .fallbackToLocal)
        #expect(service.previewRefundCallCount == 0)
        #expect(cache.isAvailable(siteID: siteID) == nil)

        // When the cached version is corrected, the next call probes normally.
        (stores.sessionManager as? SessionManager)?.cachedWooCommerceVersion = Versions.minimum
        let secondResult = await sut.previewRefund(siteID: siteID, orderID: orderID, lineItems: [lineItem()])

        // Then
        #expect(secondResult == .serverCalculated(preview()))
        #expect(cache.isAvailable(siteID: siteID) == true)
    }

    @Test func previewRefund_when_site_cached_available_but_version_below_minimum_then_falls_back() async {
        // Given a cached preview success but a below-minimum version: the version gate is
        // authoritative for the create capability and is not bypassed by the cache
        let cache = ServerRefundAvailabilityCache()
        cache.markAvailable(siteID: siteID)
        let (sut, service, _) = makeSUT(cachedWooVersion: Versions.belowMinimum, cache: cache, previewResult: .success(preview()))

        // When
        let result = await sut.previewRefund(siteID: siteID, orderID: orderID, lineItems: [lineItem()])

        // Then it falls back without probing, and the cached verdict is left untouched.
        #expect(result == .fallbackToLocal)
        #expect(service.previewRefundCallCount == 0)
        #expect(cache.isAvailable(siteID: siteID) == true)
    }

    @Test func previewRefund_when_wc_version_is_prerelease_of_minimum_then_probes() async {
        // Given a beta of the minimum version (11.1.0-beta1 must not read as below 11.1.0)
        let cache = ServerRefundAvailabilityCache()
        let (sut, _, _) = makeSUT(cachedWooVersion: Versions.betaOfMinimum, cache: cache, previewResult: .success(preview()))

        // When
        let result = await sut.previewRefund(siteID: siteID, orderID: orderID, lineItems: [lineItem()])

        // Then
        #expect(result == .serverCalculated(preview()))
        #expect(cache.isAvailable(siteID: siteID) == true)
    }

    @Test func previewRefund_when_wc_version_unknown_then_falls_back_without_probing() async {
        // Given a missing cached version, which fails closed (the preview route does not
        // prove `compute_totals` create support, so preview alone must not unlock the create).
        let cache = ServerRefundAvailabilityCache()
        let (sut, service, _) = makeSUT(cachedWooVersion: nil, cache: cache, previewResult: .success(preview()))

        // When
        let result = await sut.previewRefund(siteID: siteID, orderID: orderID, lineItems: [lineItem()])

        // Then
        #expect(result == .fallbackToLocal)
        #expect(service.previewRefundCallCount == 0)
        #expect(cache.isAvailable(siteID: siteID) == nil)
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
        let cache = ServerRefundAvailabilityCache()
        let (sut, _, _) = makeSUT(cache: cache, previewResult: .success(preview()))

        // When
        let result = await sut.previewRefund(siteID: siteID, orderID: orderID, lineItems: [lineItem()])

        // Then
        #expect(result == .serverCalculated(preview()))
        #expect(cache.isAvailable(siteID: siteID) == true)
    }

    @Test func previewRefund_when_dotcom_rest_no_route_then_marks_unavailable_and_falls_back() async {
        // Given
        let cache = ServerRefundAvailabilityCache()
        let (sut, _, _) = makeSUT(cache: cache, previewResult: .failure(DotcomError.noRestRoute()))

        // When
        let result = await sut.previewRefund(siteID: siteID, orderID: orderID, lineItems: [lineItem()])

        // Then
        #expect(result == .fallbackToLocal)
        #expect(cache.isAvailable(siteID: siteID) == false)
    }

    @Test func previewRefund_when_network_404_rest_no_route_then_marks_unavailable_and_falls_back() async {
        // Given
        let cache = ServerRefundAvailabilityCache()
        let response = Data(#"{"code":"rest_no_route"}"#.utf8)
        let (sut, _, _) = makeSUT(cache: cache, previewResult: .failure(NetworkError.notFound(response: response)))

        // When
        let result = await sut.previewRefund(siteID: siteID, orderID: orderID, lineItems: [lineItem()])

        // Then
        #expect(result == .fallbackToLocal)
        #expect(cache.isAvailable(siteID: siteID) == false)
    }

    @Test func previewRefund_when_404_without_rest_no_route_then_returns_error_without_marking_unavailable() async {
        // Given a genuine missing-resource 404 (not a missing route)
        let cache = ServerRefundAvailabilityCache()
        let response = Data(#"{"code":"woocommerce_rest_shop_order_invalid_id"}"#.utf8)
        let (sut, _, _) = makeSUT(cache: cache, previewResult: .failure(NetworkError.notFound(response: response)))

        // When
        let result = await sut.previewRefund(siteID: siteID, orderID: orderID, lineItems: [lineItem()])

        // Then the server flow stays enabled for the session; only `rest_no_route` may disable it.
        #expect(isError(result))
        #expect(cache.isAvailable(siteID: siteID) == nil)
    }

    @Test func previewRefund_when_other_error_then_returns_error_without_marking_unavailable() async {
        // Given
        let cache = ServerRefundAvailabilityCache()
        let (sut, _, _) = makeSUT(cache: cache, previewResult: .failure(NetworkError.timeout()))

        // When
        let result = await sut.previewRefund(siteID: siteID, orderID: orderID, lineItems: [lineItem()])

        // Then
        #expect(isError(result))
        #expect(cache.isAvailable(siteID: siteID) == nil)
    }

    @Test func previewRefund_when_route_missing_then_reports_the_fallback_with_the_store_woo_version() async throws {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let (sut, _, _) = makeSUT(cachedWooVersion: Versions.minimum,
                                  previewResult: .failure(DotcomError.noRestRoute()),
                                  analyticsProvider: analyticsProvider)

        // When
        _ = await sut.previewRefund(siteID: siteID, orderID: orderID, lineItems: [lineItem()])

        // Then
        let index = try #require(analyticsProvider.receivedEvents.firstIndex(of: "refund_server_flow_unavailable"))
        #expect(analyticsProvider.receivedProperties[index]["woocommerce_version"] as? String == Versions.minimum)
        #expect(analyticsProvider.receivedProperties[index]["site_id"] as? String == "\(siteID)")
    }

    @Test func previewRefund_when_preview_succeeds_then_reports_no_fallback() async {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let (sut, _, _) = makeSUT(previewResult: .success(preview()), analyticsProvider: analyticsProvider)

        // When
        _ = await sut.previewRefund(siteID: siteID, orderID: orderID, lineItems: [lineItem()])

        // Then
        #expect(analyticsProvider.receivedEvents.contains("refund_server_flow_unavailable") == false)
    }
}

private extension POSServerRefundPreviewUseCaseTests {

    /// Store version fixtures relative to `Versions.minimum`, the earliest release with the
    /// server-calculated refund endpoints (also passed to the SUT's resolver as `minimumWooVersion`).
    enum Versions {
        static let minimum = "11.1.0"
        static let betaOfMinimum = "11.1.0-beta1"
        static let belowMinimum = "11.0.9"
    }

    func makeSUT(flagEnabled: Bool = true,
                 cachedWooVersion: String? = Versions.minimum,
                 cache: ServerRefundAvailabilityCache? = nil,
                 previewResult: Swift.Result<RefundPreview, Error>? = nil,
                 analyticsProvider: MockAnalyticsProvider = MockAnalyticsProvider())
    -> (POSServerRefundPreviewUseCase, MockRefundService, MockStoresManager) {
        // Resolved in the (main-actor) test body rather than as a default argument: the cache's
        // initializer is main-actor-isolated, and default arguments are evaluated nonisolated.
        let cache = cache ?? ServerRefundAvailabilityCache()
        let session = SessionManager.testingInstance
        session.cachedWooCommerceVersion = cachedWooVersion
        let stores = MockStoresManager(sessionManager: session)
        let service = MockRefundService()
        service.previewRefundResult = previewResult
        let flags = MockFeatureFlagService()
        flags.isFeatureFlagEnabledReturnValue = [.posServerCalculatedRefunds: flagEnabled]
        let sut = POSServerRefundPreviewUseCase(refundService: service,
                                                flowResolver: POSRefundFlowResolver(stores: stores,
                                                                                    featureFlagService: flags,
                                                                                    availabilityCache: cache,
                                                                                    minimumWooVersion: Versions.minimum),
                                                availabilityCache: cache,
                                                analytics: WooAnalytics(analyticsProvider: analyticsProvider))
        return (sut, service, stores)
    }

    func lineItem() -> RefundPreviewLineItem {
        .quantityBased(lineItemID: 10, quantity: 1)
    }

    /// `.error` carries the underlying error for logging, so match on the case rather than a value.
    func isError(_ result: POSServerRefundPreviewUseCase.Result) -> Bool {
        if case .error = result {
            return true
        }
        return false
    }

    func preview() -> RefundPreview {
        RefundPreview(subtotal: 27, tax: 2.43, total: 29.43, maxRefundable: 59, breakdown: .fake())
    }
}
