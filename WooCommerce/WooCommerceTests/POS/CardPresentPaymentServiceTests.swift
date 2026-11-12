import Testing
import Foundation
@testable import PointOfSale
import Yosemite
import Combine
@testable import WooCommerce

@MainActor
struct CardPresentPaymentServiceTests {
    @Test func test_late_onboarding_when_model_is_locked_then_releases_real_readiness_before_next_request() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        let onboarding = CardPresentPaymentsOnboardingPresenterAdaptor(stores: stores)
        let service = await CardPresentPaymentService(siteID: 123, stores: stores,
                                                       collectOrderPaymentAnalyticsTracker: MockCollectOrderPaymentAnalyticsTracker(),
                                                       onboardingAdaptor: onboarding)
        defer { service.discardOnboardingPresentation() }
        let aggregate = POSPreviewHelpers.makePreviewAggregateModel(cardPresentPaymentService: service)
        let model = aggregate.paymentModel
        let session = MockPOSAccessSession(isLocked: true)
        model.presentationSession = session
        model.discardPresentationsForLock()
        var presentations = 0
        let subscription = onboarding.onboardingScreenViewModelPublisher.sink { event in
            if case .showOnboarding = event { presentations += 1 }
        }

        // When - receive the real queued facade event with no SwiftUI view mounted.
        onboarding.showOnboardingIfRequired(from: NullViewControllerPresenting()) {}
        await withCheckedContinuation { continuation in DispatchQueue.main.async { continuation.resume() } }
        onboarding.showOnboardingIfRequired(from: NullViewControllerPresenting()) {}
        await withCheckedContinuation { continuation in DispatchQueue.main.async { continuation.resume() } }

        // Then
        #expect(presentations == 2)
        #expect(model.cardPresentPaymentOnboardingViewContainer == nil)
        session.isLocked = false
        onboarding.showOnboardingIfRequired(from: NullViewControllerPresenting()) {}
        await withCheckedContinuation { continuation in DispatchQueue.main.async { continuation.resume() } }
        #expect(presentations == 3)
        #expect(model.cardPresentPaymentOnboardingViewContainer != nil)
        withExtendedLifetime(subscription) {}
    }

    @Test func test_onboarding_when_discarded_during_publishing_then_does_not_reinstall_readiness_subscription() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        let onboarding = CardPresentPaymentsOnboardingPresenterAdaptor(stores: stores)
        let service = await CardPresentPaymentService(siteID: 123, stores: stores,
                                                       collectOrderPaymentAnalyticsTracker: MockCollectOrderPaymentAnalyticsTracker(),
                                                       onboardingAdaptor: onboarding)
        defer { service.discardOnboardingPresentation() }
        var presentations = 0
        let subscription = onboarding.onboardingScreenViewModelPublisher.sink { event in
            if case .showOnboarding = event {
                presentations += 1
                service.discardOnboardingPresentation()
            }
        }

        // When
        onboarding.showOnboardingIfRequired(from: NullViewControllerPresenting()) {}
        onboarding.showOnboardingIfRequired(from: NullViewControllerPresenting()) {}

        // Then
        #expect(presentations == 2)
        withExtendedLifetime(subscription) {}
    }

    @Test(arguments: [CardReaderConnectionMethod.bluetooth, .tapToPay])
    func test_connect_when_caller_is_cancelled_then_cancels_owned_preflight_and_allows_next_connection(_ method: CardReaderConnectionMethod) async throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        var discoveryCancellations = 0
        var paymentCancellations = 0
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            switch action {
            case .cancelCardReaderDiscovery(let complete):
                discoveryCancellations += 1
                complete(.success(()))
            case .cancelPayment:
                paymentCancellations += 1
            default: break
            }
        }
        let preflight = MockPendingConnectionPreflight()
        let service = await CardPresentPaymentService(siteID: 123, stores: stores,
                                                       collectOrderPaymentAnalyticsTracker: MockCollectOrderPaymentAnalyticsTracker(),
                                                       connectionPreflight: preflight)
        let first = Task { try await service.connectReader(using: method) }
        for _ in 0..<200 where preflight.starts == 0 { try await Task.sleep(for: .milliseconds(10)) }
        try #require(preflight.starts == 1)

        // When
        first.cancel()
        _ = try await first.value
        let second = Task { try await service.connectReader(using: method) }
        for _ in 0..<200 where preflight.starts < 2 { try await Task.sleep(for: .milliseconds(10)) }
        try #require(preflight.starts == 2)
        second.cancel()
        _ = try await second.value

        // Then
        #expect(preflight.cancellations == 2)
        #expect(discoveryCancellations == 2)
        #expect(paymentCancellations == 0)
    }

    @Test func test_discard_onboarding_when_readiness_is_pending_then_next_request_presents_again_without_payment_cancellation() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        let onboarding = CardPresentPaymentsOnboardingPresenterAdaptor(stores: stores)
        let service = await CardPresentPaymentService(siteID: 123, stores: stores,
                                                       collectOrderPaymentAnalyticsTracker: MockCollectOrderPaymentAnalyticsTracker(),
                                                       onboardingAdaptor: onboarding)
        defer { service.discardOnboardingPresentation() }
        var presentations = 0
        var readinessCompletions = 0
        let subscription = onboarding.onboardingScreenViewModelPublisher.sink { event in
            if case .showOnboarding = event { presentations += 1 }
        }
        onboarding.showOnboardingIfRequired(from: NullViewControllerPresenting()) { readinessCompletions += 1 }
        #expect(presentations == 1)
        onboarding.showOnboardingIfRequired(from: NullViewControllerPresenting()) { readinessCompletions += 1 }
        #expect(presentations == 1)

        // When
        service.discardOnboardingPresentation()
        onboarding.showOnboardingIfRequired(from: NullViewControllerPresenting()) { readinessCompletions += 1 }

        // Then
        #expect(presentations == 2)
        #expect(readinessCompletions == 0)
        #expect(!stores.receivedActions.contains { action in
            guard let action = action as? CardPresentPaymentAction else { return false }
            if case .cancelPayment = action { return true }
            return false
        })
        withExtendedLifetime(subscription) {}
    }

    @Test func test_initialization_when_publisher_callbacks_are_omitted_then_completes() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))

        // When
        _ = await CardPresentPaymentService(
            siteID: 123,
            stores: stores,
            collectOrderPaymentAnalyticsTracker: MockCollectOrderPaymentAnalyticsTracker()
        )

        // Then
        let actions = stores.receivedActions.compactMap { $0 as? CardPresentPaymentAction }
        #expect(actions.count == 3)
        #expect(actions.contains { action in
            if case .publishCardReaderConnections = action { return true }
            return false
        })
        #expect(actions.contains { action in
            if case .observeCardReaderUpdateState = action { return true }
            return false
        })
        #expect(actions.contains { action in
            if case .observeCardReaderReconnectionState = action { return true }
            return false
        })
    }

    @Test func test_cancel_when_service_has_no_task_then_preserves_other_collection_confirmation() async {
        // Given
        let analytics = MockPOSAnalytics()
        var milliseconds = 0
        let tracker = POSCollectOrderPaymentAnalyticsAdaptor(analytics: analytics, monotonicMilliseconds: { milliseconds })
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        let service = await CardPresentPaymentService(siteID: 123, stores: stores, collectOrderPaymentAnalyticsTracker: tracker)
        tracker.trackCheckoutTapped()
        tracker.trackProcessingCompletion(intent: .fake(), recordPaymentConfirmation: true)
        let cancel: () -> Void = service.cancelPayment
        // When
        cancel()
        milliseconds = 100
        tracker.trackPaymentFailure(with: CancellationError())
        // Then
        #expect(analytics.events.last?.properties["pos_time_since_payment_confirmed_ms"] as? Int == 100)
    }

    @Test func test_async_cancel_when_sdk_request_starts_then_clears_confirmation_before_callback() async throws {
        // Given
        let analytics = MockPOSAnalytics()
        let tracker = POSCollectOrderPaymentAnalyticsAdaptor(analytics: analytics, monotonicMilliseconds: { 0 })
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        let service = await CardPresentPaymentService(siteID: 123, stores: stores, collectOrderPaymentAnalyticsTracker: tracker)
        tracker.trackCheckoutTapped()
        tracker.trackProcessingCompletion(intent: .fake(), recordPaymentConfirmation: true)
        var receivedCancellation = false
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            guard case .cancelPayment(let complete) = action else { return }
            receivedCancellation = true
            tracker.trackPaymentFailure(with: CancellationError())
            #expect(analytics.events.last?.properties["pos_time_since_payment_confirmed_ms"] == nil)
            complete?(.success(()))
        }
        // When
        try await service.cancelPayment()
        // Then
        #expect(receivedCancellation)
    }
}

@MainActor
private final class MockPendingConnectionPreflight: CardPresentPaymentPreflightControllerFacade {
    var starts = 0
    var cancellations = 0

    func attemptConnection(discoveryMethod: CardReaderDiscoveryMethod) async throws -> CardReaderPreflightResult {
        starts += 1
        do {
            try await Task.sleep(for: .seconds(60))
        } catch {
            cancellations += 1
            throw error
        }
        throw CancellationError()
    }
}
