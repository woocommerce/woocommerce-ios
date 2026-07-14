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
        let (sut, stores, _) = makeSUT(flagEnabled: false)

        // When
        let result = await sut.previewRefund(siteID: siteID, orderID: orderID, lineItems: [lineItem()])

        // Then
        #expect(result == .fallbackToLocal)
        #expect(stores.receivedActions.isEmpty)
    }

    @Test func previewRefund_when_site_cached_unavailable_then_falls_back_without_dispatch() async {
        // Given
        let cache = V4RefundAvailabilityCache()
        cache.markV4Unavailable(siteID: siteID)
        let (sut, stores, _) = makeSUT(cache: cache)

        // When
        let result = await sut.previewRefund(siteID: siteID, orderID: orderID, lineItems: [lineItem()])

        // Then
        #expect(result == .fallbackToLocal)
        #expect(stores.receivedActions.isEmpty)
    }

    @Test func previewRefund_when_wc_version_below_minimum_then_marks_unavailable_and_falls_back_without_dispatch() async {
        // Given
        let cache = V4RefundAvailabilityCache()
        let (sut, stores, _) = makeSUT(cachedWooVersion: "10.8.0", cache: cache)

        // When
        let result = await sut.previewRefund(siteID: siteID, orderID: orderID, lineItems: [lineItem()])

        // Then
        #expect(result == .fallbackToLocal)
        #expect(stores.receivedActions.isEmpty)
        #expect(cache.isV4Available(siteID: siteID) == false)
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
        let (sut, stores, _) = makeSUT()

        // When
        let result = await sut.previewRefund(siteID: siteID, orderID: orderID, lineItems: [])

        // Then
        #expect(result == .fallbackToLocal)
        #expect(stores.receivedActions.isEmpty)
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
    -> (POSV4RefundPreviewUseCase, MockStoresManager, MockFeatureFlagService) {
        // Resolved in the (main-actor) test body rather than as a default argument: the cache's
        // initializer is main-actor-isolated, and default arguments are evaluated nonisolated.
        let cache = cache ?? V4RefundAvailabilityCache()
        let session = SessionManager.testingInstance
        session.cachedWooCommerceVersion = cachedWooVersion
        let stores = MockStoresManager(sessionManager: session)
        if let previewResult {
            stores.whenReceivingAction(ofType: RefundAction.self) { action in
                guard case let .previewRefund(_, _, _, completion) = action else {
                    return
                }
                completion(previewResult)
            }
        }
        let flags = MockFeatureFlagService()
        flags.isFeatureFlagEnabledReturnValue = [.posRefundsV4: flagEnabled]
        let sut = POSV4RefundPreviewUseCase(stores: stores,
                                            featureFlagService: flags,
                                            availabilityCache: cache,
                                            minimumWooVersion: "10.9.0")
        return (sut, stores, flags)
    }

    func lineItem() -> RefundV4LineItem {
        .quantityBased(lineItemID: 10, quantity: 1)
    }

    func preview() -> RefundPreview {
        RefundPreview(subtotal: 27, tax: 2.43, total: 29.43, maxRefundable: 59, breakdown: .fake())
    }
}
