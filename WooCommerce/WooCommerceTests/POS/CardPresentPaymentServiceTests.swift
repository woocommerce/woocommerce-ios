import Foundation
import Testing
import PointOfSale
import Yosemite
@testable import WooCommerce

@MainActor
@Suite(.serialized, .timeLimit(.minutes(5)))
struct CardPresentPaymentServiceTests {
    @Test(arguments: [true, false])
    func test_cancel_when_reader_confirmed_but_capture_is_unknown_then_no_active_intent_is_not_proof(captureSucceeds: Bool) async throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        let processingCompleted = AsyncStream<Void>.makeStream()
        var finishCapture: CheckedContinuation<CardPresentPaymentAdaptedCollectOrderPaymentResult, Error>?
        let service = await CardPresentPaymentService(siteID: 123, stores: stores,
            collectOrderPaymentAnalyticsTracker: MockCollectOrderPaymentAnalyticsTracker(),
            paymentTaskFactory: { _, _, _, onProcessingCompletion in Task { @MainActor in
                try await withCheckedThrowingContinuation { continuation in
                    finishCapture = continuation
                    onProcessingCompletion()
                    processingCompleted.continuation.yield(())
                }
            } })
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            guard case .cancelPayment(let complete) = action else { return }
            complete?(.failure(CardReaderServiceError.paymentCancellation(underlyingError: .noActivePaymentIntent)))
        }
        let collection = Task { try await service.collectPayment(for: .fake(), using: .bluetooth, channel: .pos) }
        var iterator = processingCompleted.stream.makeAsyncIterator()
        _ = await iterator.next()

        // When
        await #expect(throws: (any Error).self) { try await service.cancelPayment() }

        // Then
        #expect(service.paymentSessionState == .unresolved)
        await #expect(throws: (any Error).self) {
            try await service.collectPayment(for: .fake(), using: .tapToPay, channel: .pos)
        }

        // When
        if captureSucceeds {
            finishCapture?.resume(returning: .success(cardDetails: nil))
        } else {
            finishCapture?.resume(throwing: CancellationError())
        }
        _ = try? await collection.value

        // Then
        #expect(service.paymentSessionState == (captureSucceeds ? .idle : .unresolved))
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            guard case .cancelPayment(let complete) = action else { return }
            complete?(.success(()))
        }
        try await service.cancelPayment()
    }

    @Test func test_collect_when_task_stops_without_proof_then_preserves_unresolved_lifetime_and_blocks_reentry() async throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        let service = await CardPresentPaymentService(siteID: 123, stores: stores,
            collectOrderPaymentAnalyticsTracker: MockCollectOrderPaymentAnalyticsTracker(),
            paymentTaskFactory: { _, _, _, _ in Task { throw CancellationError() } })

        // When
        _ = try? await service.collectPayment(for: .fake(), using: .bluetooth, channel: .pos)

        // Then
        #expect(service.paymentSessionState == .unresolved)
        await #expect(throws: (any Error).self) {
            try await service.collectPayment(for: .fake(), using: .tapToPay, channel: .pos)
        }
        let replacementStores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        let replacement = await CardPresentPaymentService(siteID: 456, stores: replacementStores,
            collectOrderPaymentAnalyticsTracker: MockCollectOrderPaymentAnalyticsTracker())
        #expect(replacement.paymentSessionState == .unresolved)
        await #expect(throws: (any Error).self) {
            try await replacement.collectPayment(for: .fake(), using: .tapToPay, channel: .pos)
        }
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            guard case .cancelPayment(let complete) = action else { return }
            complete?(.success(()))
        }
        try await replacement.cancelPayment()
        #expect(service.paymentSessionState == .idle)
    }

    @Test func test_cancel_when_sdk_fails_then_remains_unresolved_until_a_confirmed_cancel() async throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        let service = await CardPresentPaymentService(siteID: 123, stores: stores,
            collectOrderPaymentAnalyticsTracker: MockCollectOrderPaymentAnalyticsTracker(),
            paymentTaskFactory: { _, _, _, _ in Task { throw CancellationError() } })
        _ = try? await service.collectPayment(for: .fake(), using: .bluetooth, channel: .pos)
        var cancellationCount = 0
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            guard case .cancelPayment(let complete) = action else { return }
            cancellationCount += 1
            #expect(service.paymentSessionState == .cancelling)
            complete?(cancellationCount == 1 ? .failure(CancellationError()) : .success(()))
        }

        // When
        try? await service.cancelPayment()

        // Then
        #expect(service.paymentSessionState == .unresolved)

        // When
        try await service.cancelPayment()

        // Then
        #expect(service.paymentSessionState == .idle)
        #expect(cancellationCount == 2)
    }

    @Test func test_cancel_when_late_success_arrives_then_drains_cancel_before_releasing_lifetime() async throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        let cancellationStarted = AsyncStream<Void>.makeStream()
        var requestCount = 0
        let repeatedRequestStarted = AsyncStream<Void>.makeStream()
        var repeatedCancellation: Task<Void, Error>?
        var finishCancellation: ((Result<Void, Error>) -> Void)?
        var cancellation: Task<Void, Error>?
        var service: CardPresentPaymentService!
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            guard case .cancelPayment(let complete) = action else { return }
            requestCount += 1
            finishCancellation = complete
            cancellationStarted.continuation.yield(())
        }
        service = await CardPresentPaymentService(siteID: 123, stores: stores,
            collectOrderPaymentAnalyticsTracker: MockCollectOrderPaymentAnalyticsTracker(),
            paymentTaskFactory: { _, _, _, _ in Task { @MainActor in
                cancellation = Task { try await service.cancelPayment() }
                repeatedCancellation = Task {
                    repeatedRequestStarted.continuation.yield(())
                    try await service.cancelPayment()
                }
                var iterator = cancellationStarted.stream.makeAsyncIterator()
                _ = await iterator.next()
                return .success(cardDetails: nil)
            } })

        // When
        _ = try await service.collectPayment(for: .fake(), using: .bluetooth, channel: .pos)

        // Then
        #expect(service.paymentSessionState == .cancelling)

        // When
        var repeatedIterator = repeatedRequestStarted.stream.makeAsyncIterator()
        _ = await repeatedIterator.next()
        finishCancellation?(.failure(CancellationError()))
        try? await cancellation?.value
        try? await repeatedCancellation?.value

        // Then
        #expect(requestCount == 1)
        #expect(service.paymentSessionState == .idle)
    }

    @Test func test_cancel_when_no_payment_has_started_then_no_active_intent_allows_first_collection() async throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        let service = await CardPresentPaymentService(siteID: 123, stores: stores,
            collectOrderPaymentAnalyticsTracker: MockCollectOrderPaymentAnalyticsTracker(),
            paymentTaskFactory: { _, _, _, _ in Task { .success(cardDetails: nil) } })
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            guard case .cancelPayment(let complete) = action else { return }
            complete?(.failure(CardReaderServiceError.paymentCancellation(underlyingError: .noActivePaymentIntent)))
        }

        // When
        try await service.cancelPayment()
        _ = try await service.collectPayment(for: .fake(), using: .bluetooth, channel: .pos)

        // Then
        #expect(service.paymentSessionState == .idle)
    }

    @Test func test_collect_when_old_result_arrives_after_confirmed_cancel_then_preserves_new_attempt() async throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        let cancellationStarted = AsyncStream<Void>.makeStream()
        var releaseOldResult: (() -> Void)?
        var finishCancellation: ((Result<Void, Error>) -> Void)?
        var cancellation: Task<Void, Error>?
        var oldCollection: Task<CardPresentPaymentResult, Error>?
        var invocation = 0
        var service: CardPresentPaymentService!
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            guard case .cancelPayment(let complete) = action else { return }
            finishCancellation = complete
            cancellationStarted.continuation.yield(())
        }
        service = await CardPresentPaymentService(siteID: 123, stores: stores,
            collectOrderPaymentAnalyticsTracker: MockCollectOrderPaymentAnalyticsTracker(),
            paymentTaskFactory: { _, _, _, _ in
                invocation += 1
                if invocation == 1 {
                    return Task { @MainActor in
                        await withCheckedContinuation { continuation in
                            releaseOldResult = { continuation.resume() }
                            cancellation = Task { try await service.cancelPayment() }
                        }
                        return .success(cardDetails: nil)
                    }
                }
                return Task { @MainActor in
                    releaseOldResult?()
                    do {
                        _ = try await oldCollection?.value
                        Issue.record("The cancelled owner's late result was accepted")
                    } catch is CancellationError {} catch { Issue.record("Unexpected error: \(error)") }
                    #expect(service.paymentSessionState == .active)
                    return .success(cardDetails: nil)
                }
            })
        oldCollection = Task { try await service.collectPayment(for: .fake(), using: .bluetooth, channel: .pos) }
        var iterator = cancellationStarted.stream.makeAsyncIterator()
        _ = await iterator.next()
        finishCancellation?(.success(()))
        try await cancellation?.value

        // When
        _ = try await service.collectPayment(for: .fake(), using: .tapToPay, channel: .pos)

        // Then
        #expect(invocation == 2)
        #expect(service.paymentSessionState == .idle)
    }

    @Test func test_cancel_when_sdk_fails_and_cancelled_task_returns_late_then_keeps_outcome_unresolved() async throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        let started = AsyncStream<Void>.makeStream()
        var finishCollection: (() -> Void)?
        let service = await CardPresentPaymentService(siteID: 123, stores: stores,
            collectOrderPaymentAnalyticsTracker: MockCollectOrderPaymentAnalyticsTracker(),
            paymentTaskFactory: { _, _, _, _ in Task { @MainActor in
                try await withCheckedThrowingContinuation { continuation in
                    finishCollection = { continuation.resume(throwing: CancellationError()) }
                    started.continuation.yield(())
                }
            } })
        let collection = Task { try await service.collectPayment(for: .fake(), using: .bluetooth, channel: .pos) }
        var iterator = started.stream.makeAsyncIterator()
        _ = await iterator.next()
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            guard case .cancelPayment(let complete) = action else { return }
            complete?(.failure(CancellationError()))
        }

        // When
        try? await service.cancelPayment()

        // Then
        #expect(service.paymentSessionState == .unresolved)
        await #expect(throws: (any Error).self) {
            try await service.collectPayment(for: .fake(), using: .tapToPay, channel: .pos)
        }

        // When
        finishCollection?()
        _ = await collection.result

        // Then
        #expect(service.paymentSessionState == .unresolved)

        // When
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            guard case .cancelPayment(let complete) = action else { return }
            complete?(.success(()))
        }
        try await service.cancelPayment()

        // Then
        #expect(service.paymentSessionState == .idle)
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
