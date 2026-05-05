import Foundation
import Testing
import UIKit
import Yosemite
import WooAIAssistant
@testable import WooCommerce

@MainActor
struct AIAssistantExternalNavigationAdaptorTests {

    @Test
    func test_openOrder_pushes_a_loader_view_controller_synchronously() {
        // Given
        let stores = ThreadCapturingStoresManager(sessionManager: .makeForTesting(authenticated: true))
        let host = AIAssistantNavigationHost()
        let nav = UINavigationController(rootViewController: UIViewController())
        host.attach(nav)
        let sut = AIAssistantExternalNavigationAdaptor(siteID: 123, navigationHost: host, stores: stores)

        // When
        sut.openOrder(orderID: 456)

        // Then
        #expect(nav.topViewController is OrderLoaderViewController)
    }

    @Test
    func test_openProduct_dispatches_retrieve_on_main_thread() async {
        // Given
        let stores = ThreadCapturingStoresManager(sessionManager: .makeForTesting(authenticated: true))
        let host = AIAssistantNavigationHost()
        let sut = AIAssistantExternalNavigationAdaptor(siteID: 123, navigationHost: host, stores: stores)

        // When
        sut.openProduct(productID: 789)
        let captured = await stores.waitForFirstDispatch()

        // Then
        #expect(captured.action is ProductAction)
        #expect(captured.wasOnMainThread)
    }

    @Test
    func test_openProductVariation_dispatches_retrieve_on_main_thread() async {
        // Given
        let stores = ThreadCapturingStoresManager(sessionManager: .makeForTesting(authenticated: true))
        let host = AIAssistantNavigationHost()
        let sut = AIAssistantExternalNavigationAdaptor(siteID: 123, navigationHost: host, stores: stores)

        // When
        sut.openProductVariation(productID: 1, variationID: 2)
        let captured = await stores.waitForFirstDispatch()

        // Then
        #expect(captured.action is ProductAction || captured.action is ProductVariationAction)
        #expect(captured.wasOnMainThread)
    }

    @Test
    func test_openCustomer_dispatches_on_main_thread() async {
        // Given
        let stores = ThreadCapturingStoresManager(sessionManager: .makeForTesting(authenticated: true))
        let host = AIAssistantNavigationHost()
        let sut = AIAssistantExternalNavigationAdaptor(siteID: 123, navigationHost: host, stores: stores)

        // When
        sut.openCustomer(customerID: 7)
        let captured = await stores.waitForFirstDispatch()

        // Then
        #expect(captured.action is CustomerAction)
        #expect(captured.wasOnMainThread)
    }

    @Test
    func test_openProduct_pushes_loading_placeholder_synchronously() {
        // Given
        let stores = ThreadCapturingStoresManager(sessionManager: .makeForTesting(authenticated: true))
        let host = AIAssistantNavigationHost()
        let nav = UINavigationController(rootViewController: UIViewController())
        host.attach(nav)
        let sut = AIAssistantExternalNavigationAdaptor(siteID: 123, navigationHost: host, stores: stores)

        // When
        sut.openProduct(productID: 789)

        // Then
        #expect(nav.topViewController is AIAssistantLoadingPlaceholderViewController)
    }

    @Test
    func test_openProductVariation_pushes_loading_placeholder_synchronously() {
        // Given
        let stores = ThreadCapturingStoresManager(sessionManager: .makeForTesting(authenticated: true))
        let host = AIAssistantNavigationHost()
        let nav = UINavigationController(rootViewController: UIViewController())
        host.attach(nav)
        let sut = AIAssistantExternalNavigationAdaptor(siteID: 123, navigationHost: host, stores: stores)

        // When
        sut.openProductVariation(productID: 1, variationID: 2)

        // Then
        #expect(nav.topViewController is AIAssistantLoadingPlaceholderViewController)
    }

    @Test
    func test_openCustomer_pushes_loading_placeholder_synchronously() {
        // Given
        let stores = ThreadCapturingStoresManager(sessionManager: .makeForTesting(authenticated: true))
        let host = AIAssistantNavigationHost()
        let nav = UINavigationController(rootViewController: UIViewController())
        host.attach(nav)
        let sut = AIAssistantExternalNavigationAdaptor(siteID: 123, navigationHost: host, stores: stores)

        // When
        sut.openCustomer(customerID: 7)

        // Then
        #expect(nav.topViewController is AIAssistantLoadingPlaceholderViewController)
    }

    @Test
    func test_openCustomer_when_fetch_succeeds_then_swaps_placeholder_for_detail() async {
        // Given
        let stores = StubbingStoresManager(sessionManager: .makeForTesting(authenticated: true))
        let customer = Customer(siteID: 123,
                                customerID: 7,
                                email: "buyer@example.test",
                                username: "buyer",
                                firstName: "Sample",
                                lastName: "Buyer",
                                billing: nil,
                                shipping: nil)
        stores.stubCustomerFetch = .success(customer)
        let host = AIAssistantNavigationHost()
        let nav = UINavigationController(rootViewController: UIViewController())
        host.attach(nav)
        let sut = AIAssistantExternalNavigationAdaptor(siteID: 123, navigationHost: host, stores: stores)

        // When
        sut.openCustomer(customerID: 7)
        await stores.waitForFirstDispatch()
        await waitForMainRunLoop()

        // Then
        #expect(!(nav.topViewController is AIAssistantLoadingPlaceholderViewController))
        #expect(nav.topViewController is UIHostingController<CustomerDetailView>)
    }

    @Test
    func test_openCustomer_when_fetch_returns_nil_then_placeholder_stays() async {
        // Given
        let stores = StubbingStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.stubCustomerFetch = .failure(SampleError.fetchFailed)
        let host = AIAssistantNavigationHost()
        let nav = UINavigationController(rootViewController: UIViewController())
        host.attach(nav)
        let sut = AIAssistantExternalNavigationAdaptor(siteID: 123, navigationHost: host, stores: stores)

        // When
        sut.openCustomer(customerID: 7)
        await stores.waitForFirstDispatch()
        await waitForMainRunLoop()

        // Then
        #expect(nav.topViewController is AIAssistantLoadingPlaceholderViewController)
    }

    @Test
    func test_openCustomer_when_placeholder_popped_before_fetch_resolves_then_no_swap() async {
        // Given
        let stores = StubbingStoresManager(sessionManager: .makeForTesting(authenticated: true))
        let customer = Customer(siteID: 123,
                                customerID: 7,
                                email: "buyer@example.test",
                                username: nil,
                                firstName: nil,
                                lastName: nil,
                                billing: nil,
                                shipping: nil)
        stores.deferCompletion = true
        stores.stubCustomerFetch = .success(customer)
        let rootVC = UIViewController()
        let host = AIAssistantNavigationHost()
        let nav = UINavigationController(rootViewController: rootVC)
        host.attach(nav)
        let sut = AIAssistantExternalNavigationAdaptor(siteID: 123, navigationHost: host, stores: stores)

        // When
        sut.openCustomer(customerID: 7)
        await stores.waitForFirstDispatch()
        nav.setViewControllers([rootVC], animated: false)
        stores.releaseDeferredCompletion()
        await waitForMainRunLoop()

        // Then
        #expect(nav.viewControllers.count == 1)
        #expect(nav.topViewController === rootVC)
    }

    @Test
    func test_openAnalyticsHub_pushes_an_analytics_hub_view_controller() {
        // Given
        let stores = ThreadCapturingStoresManager(sessionManager: .makeForTesting(authenticated: true))
        let host = AIAssistantNavigationHost()
        let nav = UINavigationController(rootViewController: UIViewController())
        host.attach(nav)
        let sut = AIAssistantExternalNavigationAdaptor(siteID: 123, navigationHost: host, stores: stores)

        // When
        sut.openAnalyticsHub(payload: .object([:]))

        // Then
        #expect(nav.topViewController is AnalyticsHubHostingViewController)
    }

    @Test
    func test_timeRange_when_payload_has_iso_dates_then_returns_custom_range() {
        // Given
        let stores = ThreadCapturingStoresManager(sessionManager: .makeForTesting(authenticated: true))
        let host = AIAssistantNavigationHost()
        let sut = AIAssistantExternalNavigationAdaptor(siteID: 123, navigationHost: host, stores: stores)
        let payload = AnyCodableJSON.object([
            "after": .string("2026-04-01"),
            "before": .string("2026-04-30")
        ])

        // When
        let range = sut.timeRange(fromAnalyticsPayload: payload)

        // Then
        guard case .custom = range else {
            Issue.record("Expected custom range, got \(range)")
            return
        }
    }

    @Test
    func test_timeRange_when_payload_has_no_dates_then_returns_today() {
        // Given
        let stores = ThreadCapturingStoresManager(sessionManager: .makeForTesting(authenticated: true))
        let host = AIAssistantNavigationHost()
        let sut = AIAssistantExternalNavigationAdaptor(siteID: 123, navigationHost: host, stores: stores)

        // When
        let range = sut.timeRange(fromAnalyticsPayload: .object([:]))

        // Then
        #expect(range == .today)
    }
}

private final class ThreadCapturingStoresManager: MockStoresManager {
    struct Capture {
        let action: Action
        let wasOnMainThread: Bool
    }

    private var captures: [Capture] = []
    private var pendingContinuations: [CheckedContinuation<Capture, Never>] = []

    override func dispatch(_ action: Action) {
        let capture = Capture(action: action, wasOnMainThread: Thread.isMainThread)
        if let next = pendingContinuations.first {
            pendingContinuations.removeFirst()
            next.resume(returning: capture)
        } else {
            captures.append(capture)
        }
    }

    func waitForFirstDispatch() async -> Capture {
        if let first = captures.first {
            return first
        }
        return await withCheckedContinuation { continuation in
            pendingContinuations.append(continuation)
        }
    }
}

private enum SampleError: Error { case fetchFailed }

private final class StubbingStoresManager: MockStoresManager {
    var stubCustomerFetch: Result<Customer, Error>?
    var stubProductFetch: Result<Product, Error>?
    var stubProductVariationFetch: Result<ProductVariation, Error>?

    var deferCompletion = false
    private var deferredFire: (() -> Void)?

    private var dispatchContinuations: [CheckedContinuation<Void, Never>] = []
    private var dispatchCount = 0

    override func dispatch(_ action: Action) {
        dispatchCount += 1

        switch action {
        case let customerAction as CustomerAction:
            handle(customerAction)
        case let productAction as ProductAction:
            handle(productAction)
        case let variationAction as ProductVariationAction:
            handle(variationAction)
        default:
            break
        }

        notifyDispatchObservers()
    }

    private func handle(_ action: CustomerAction) {
        guard case let .retrieveCustomer(_, _, onCompletion) = action,
              let stub = stubCustomerFetch else { return }
        fireOrDefer { onCompletion(stub) }
    }

    private func handle(_ action: ProductAction) {
        guard case let .retrieveProduct(_, _, onCompletion) = action,
              let stub = stubProductFetch else { return }
        fireOrDefer { onCompletion(stub) }
    }

    private func handle(_ action: ProductVariationAction) {
        guard case let .retrieveProductVariation(_, _, _, onCompletion) = action,
              let stub = stubProductVariationFetch else { return }
        fireOrDefer { onCompletion(stub) }
    }

    private func fireOrDefer(_ work: @escaping () -> Void) {
        if deferCompletion {
            deferredFire = work
        } else {
            work()
        }
    }

    func releaseDeferredCompletion() {
        let work = deferredFire
        deferredFire = nil
        work?()
    }

    private func notifyDispatchObservers() {
        let waiters = dispatchContinuations
        dispatchContinuations.removeAll()
        for continuation in waiters {
            continuation.resume()
        }
    }

    func waitForFirstDispatch() async {
        if dispatchCount > 0 { return }
        await withCheckedContinuation { continuation in
            dispatchContinuations.append(continuation)
        }
    }
}

@MainActor
private func waitForMainRunLoop() async {
    for _ in 0..<3 {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async { continuation.resume() }
        }
    }
}
