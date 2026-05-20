import Testing
import Foundation
import Yosemite
@testable import WooCommerce

@MainActor
struct PushNotificationPreferencesViewModelTests {

    private let siteID: Int64 = 123

    /// Build the SUT with a zero debounce so saves fire on the next runloop
    /// tick. Combine's `.debounce` still coalesces synchronous bursts of
    /// edits, so rapid setter calls in the same MainActor turn collapse to
    /// one save.
    private func makeSUT(stores: MockStoresManager,
                         debounceDelay: DispatchQueue.SchedulerTimeType.Stride = .zero) -> PushNotificationPreferencesViewModel {
        PushNotificationPreferencesViewModel(siteID: siteID, stores: stores, debounceDelay: debounceDelay)
    }

    private func makeStores() -> MockStoresManager {
        MockStoresManager(sessionManager: .testingInstance)
    }

    // MARK: - Loading

    @Test func test_load_when_remote_succeeds_then_loadState_becomes_loaded_and_toggles_reflect_response() async throws {
        // Given
        let stores = makeStores()
        let response = PushNotificationPreferences(
            storeOrder: .init(enabled: true),
            storeReview: .init(enabled: false),
            storeStock: .init(enabled: true)
        )
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case let .loadPushNotificationPreferences(_, onCompletion) = action {
                onCompletion(.success(response))
            }
        }
        let sut = makeSUT(stores: stores)

        // When
        await sut.load()

        // Then
        #expect(sut.loadState == .loaded)
        #expect(sut.isStoreOrderEnabled == true)
        #expect(sut.isStoreReviewEnabled == false)
        #expect(sut.isStoreStockEnabled == true)
    }

    @Test func test_load_when_remote_fails_then_loadState_becomes_error() async throws {
        // Given
        struct AnyError: Error {}
        let stores = makeStores()
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case let .loadPushNotificationPreferences(_, onCompletion) = action {
                onCompletion(.failure(AnyError()))
            }
        }
        let sut = makeSUT(stores: stores)

        // When
        await sut.load()

        // Then
        #expect(sut.loadState == .error)
    }

    @Test func test_load_when_unsaved_edits_exist_then_response_does_not_stomp_displayed_state() async throws {
        // Given the user has flipped a toggle (creating an unsaved edit) before a fresh load.
        let stores = makeStores()
        let response = PushNotificationPreferences(
            storeOrder: .init(enabled: false),
            storeReview: .init(enabled: false),
            storeStock: .init(enabled: false)
        )
        let pendingLoadCompletion = PendingLoadCompletion()
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            switch action {
            case let .loadPushNotificationPreferences(_, onCompletion):
                pendingLoadCompletion.handler = onCompletion
            case let .updatePushNotificationPreferences(_, changes, onCompletion):
                // The optimistic edit triggers a save; complete it so the SUT's
                // consumer task doesn't leak a checked continuation.
                onCompletion(.success(changes))
            default:
                break
            }
        }
        let sut = makeSUT(stores: stores)

        // When the user flips a toggle before the load returns, then the load resolves.
        sut.setStoreOrderEnabled(true)
        async let load: () = sut.load()
        // Wait until `load()` has actually registered its continuation, otherwise
        // resolving the handler too early no-ops and the test hangs.
        _ = try await wait { pendingLoadCompletion.handler != nil }
        pendingLoadCompletion.handler?(.success(response))
        await load

        // Then the optimistic UI is preserved despite the response.
        #expect(sut.isStoreOrderEnabled == true)
    }

    // MARK: - Individual setters

    @Test func test_setStoreOrderEnabled_dispatches_update_with_only_store_order_field() async throws {
        // Given
        let stores = makeStores()
        let dispatched = DispatchedChanges()
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case let .updatePushNotificationPreferences(_, changes, onCompletion) = action {
                dispatched.append(changes)
                onCompletion(.success(changes))
            }
        }
        let sut = makeSUT(stores: stores)

        // When
        sut.setStoreOrderEnabled(true)
        _ = try await wait { dispatched.calls.count >= 1 }

        // Then
        #expect(dispatched.calls.count == 1)
        #expect(dispatched.last?.storeOrder?.enabled == true)
        #expect(dispatched.last?.storeReview == nil)
        #expect(dispatched.last?.storeStock == nil)
    }

    @Test func test_setStoreReviewEnabled_dispatches_update_with_only_store_review_field() async throws {
        // Given
        let stores = makeStores()
        let dispatched = DispatchedChanges()
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case let .updatePushNotificationPreferences(_, changes, onCompletion) = action {
                dispatched.append(changes)
                onCompletion(.success(changes))
            }
        }
        let sut = makeSUT(stores: stores)

        // When
        sut.setStoreReviewEnabled(true)
        _ = try await wait { dispatched.calls.count >= 1 }

        // Then
        #expect(dispatched.last?.storeReview?.enabled == true)
        #expect(dispatched.last?.storeOrder == nil)
        #expect(dispatched.last?.storeStock == nil)
    }

    @Test func test_setStoreStockEnabled_dispatches_update_with_only_store_stock_field() async throws {
        // Given
        let stores = makeStores()
        let dispatched = DispatchedChanges()
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case let .updatePushNotificationPreferences(_, changes, onCompletion) = action {
                dispatched.append(changes)
                onCompletion(.success(changes))
            }
        }
        let sut = makeSUT(stores: stores)

        // When
        sut.setStoreStockEnabled(true)
        _ = try await wait { dispatched.calls.count >= 1 }

        // Then
        #expect(dispatched.last?.storeStock?.enabled == true)
        #expect(dispatched.last?.storeOrder == nil)
        #expect(dispatched.last?.storeReview == nil)
    }

    // MARK: - Debounce and conflate

    @Test func test_three_rapid_setter_calls_coalesce_into_one_dispatch_with_all_fields() async throws {
        // Given
        let stores = makeStores()
        let dispatched = DispatchedChanges()
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case let .updatePushNotificationPreferences(_, changes, onCompletion) = action {
                dispatched.append(changes)
                onCompletion(.success(changes))
            }
        }
        let sut = makeSUT(stores: stores)

        // When three setters fire synchronously — the @MainActor consumer can't
        // start processing until we yield, so drop-oldest collapses them to one.
        sut.setStoreOrderEnabled(true)
        sut.setStoreReviewEnabled(true)
        sut.setStoreStockEnabled(true)
        _ = try await wait { dispatched.calls.count >= 1 }
        // Give the consumer a comfortable window to fire a (would-be) second dispatch
        // if conflation isn't working, then re-check.
        try await Task.sleep(for: .milliseconds(50))

        // Then exactly one dispatch fired carrying all three changed sections.
        #expect(dispatched.calls.count == 1)
        #expect(dispatched.last?.storeOrder?.enabled == true)
        #expect(dispatched.last?.storeReview?.enabled == true)
        #expect(dispatched.last?.storeStock?.enabled == true)
    }

    @Test func test_edits_while_save_in_flight_are_queued_then_dispatched_after_completion() async throws {
        // Given a mock that holds the first dispatch's completion to keep it in flight.
        let stores = makeStores()
        let dispatched = DispatchedChanges()
        let firstCompletion = PendingCompletion()
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            guard case let .updatePushNotificationPreferences(_, changes, onCompletion) = action else {
                return
            }
            dispatched.append(changes)
            if dispatched.calls.count == 1 {
                firstCompletion.handler = onCompletion
            } else {
                onCompletion(.success(changes))
            }
        }
        let sut = makeSUT(stores: stores)

        // When the first save starts and the user flips two more toggles while it's in flight.
        sut.setStoreOrderEnabled(true)
        _ = try await wait { dispatched.calls.count >= 1 && firstCompletion.handler != nil }

        sut.setStoreReviewEnabled(true)
        sut.setStoreStockEnabled(true)
        // Allow the queue to settle; we expect at most one trigger to remain because of drop-oldest.
        try await Task.sleep(for: .milliseconds(30))

        // Release the first save so the consumer picks up the queued trigger.
        firstCompletion.handler?(.success(PushNotificationPreferences(storeOrder: .init(enabled: true))))
        _ = try await wait { dispatched.calls.count >= 2 }
        try await Task.sleep(for: .milliseconds(50))

        // Then exactly two dispatches fired total.
        #expect(dispatched.calls.count == 2)
        // And the second dispatch carries the conflated diff for the two newer edits.
        #expect(dispatched.calls[1].storeOrder == nil)
        #expect(dispatched.calls[1].storeReview?.enabled == true)
        #expect(dispatched.calls[1].storeStock?.enabled == true)
    }

    @Test func test_edit_during_debounce_window_restarts_the_countdown() async throws {
        // Given a non-zero debounce so we can observe the countdown.
        let stores = makeStores()
        let dispatched = DispatchedChanges()
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case let .updatePushNotificationPreferences(_, changes, onCompletion) = action {
                dispatched.append(changes)
                onCompletion(.success(changes))
            }
        }
        let debounce: DispatchQueue.SchedulerTimeType.Stride = .milliseconds(150)
        let sut = makeSUT(stores: stores, debounceDelay: debounce)

        // When the user edits, waits past most of the window, then edits again.
        sut.setStoreOrderEnabled(true)
        try await Task.sleep(for: .milliseconds(100))
        sut.setStoreReviewEnabled(true)

        // Then no save has fired yet — the second edit reset the timer, so the
        // original 150ms deadline at t=150 has already been cancelled.
        try await Task.sleep(for: .milliseconds(100))
        #expect(dispatched.calls.isEmpty)

        // And the save fires once after the new debounce window from the second edit.
        _ = try await wait(timeout: .milliseconds(300)) { dispatched.calls.count >= 1 }
        try await Task.sleep(for: .milliseconds(50))
        #expect(dispatched.calls.count == 1)
        #expect(dispatched.last?.storeOrder?.enabled == true)
        #expect(dispatched.last?.storeReview?.enabled == true)
    }

    @Test func test_toggle_flipped_back_within_debounce_window_produces_no_dispatch() async throws {
        // Given a non-zero debounce so we can flip on-then-off inside the window.
        let stores = makeStores()
        let dispatched = DispatchedChanges()
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            switch action {
            case let .loadPushNotificationPreferences(_, onCompletion):
                onCompletion(.success(PushNotificationPreferences(
                    storeOrder: .init(enabled: false),
                    storeReview: .init(enabled: false),
                    storeStock: .init(enabled: false)
                )))
            case let .updatePushNotificationPreferences(_, changes, onCompletion):
                dispatched.append(changes)
                onCompletion(.success(changes))
            default:
                break
            }
        }
        let sut = makeSUT(stores: stores, debounceDelay: .milliseconds(100))
        await sut.load()

        // When the user flips a toggle on and then off again before the debounce fires.
        sut.setStoreOrderEnabled(true)
        sut.setStoreOrderEnabled(false)
        // Wait well past the debounce window.
        try await Task.sleep(for: .milliseconds(200))

        // Then no update dispatch was made — the diff against `lastSaved` is empty.
        #expect(dispatched.calls.isEmpty)
    }

    // MARK: - Failure rollback

    @Test func test_setStoreOrderEnabled_when_remote_fails_then_reverts_optimistic_state_and_surfaces_notice() async throws {
        // Given
        struct AnyError: Error {}
        let stores = makeStores()
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case let .updatePushNotificationPreferences(_, _, onCompletion) = action {
                onCompletion(.failure(AnyError()))
            }
        }
        let sut = makeSUT(stores: stores)
        #expect(sut.isStoreOrderEnabled == false)

        // When
        sut.setStoreOrderEnabled(true)
        _ = try await wait { sut.errorNotice != nil }

        // Then
        #expect(sut.isStoreOrderEnabled == false)
        #expect(sut.errorNotice != nil)
    }

    @Test func test_setStoreReviewEnabled_when_remote_fails_then_reverts_optimistic_state_and_surfaces_notice() async throws {
        // Given
        struct AnyError: Error {}
        let stores = makeStores()
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case let .updatePushNotificationPreferences(_, _, onCompletion) = action {
                onCompletion(.failure(AnyError()))
            }
        }
        let sut = makeSUT(stores: stores)
        #expect(sut.isStoreReviewEnabled == false)

        // When
        sut.setStoreReviewEnabled(true)
        _ = try await wait { sut.errorNotice != nil }

        // Then
        #expect(sut.isStoreReviewEnabled == false)
        #expect(sut.errorNotice != nil)
    }

    @Test func test_setStoreStockEnabled_when_remote_fails_then_reverts_optimistic_state_and_surfaces_notice() async throws {
        // Given
        struct AnyError: Error {}
        let stores = makeStores()
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case let .updatePushNotificationPreferences(_, _, onCompletion) = action {
                onCompletion(.failure(AnyError()))
            }
        }
        let sut = makeSUT(stores: stores)
        #expect(sut.isStoreStockEnabled == false)

        // When
        sut.setStoreStockEnabled(true)
        _ = try await wait { sut.errorNotice != nil }

        // Then
        #expect(sut.isStoreStockEnabled == false)
        #expect(sut.errorNotice != nil)
    }

    @Test func test_failure_with_newer_edits_in_flight_then_optimistic_state_is_preserved() async throws {
        // Given the first save will fail. We hold its completion so we can flip a
        // newer toggle before the failure lands.
        struct AnyError: Error {}
        let stores = makeStores()
        let firstCompletion = PendingCompletion()
        let dispatched = DispatchedChanges()
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            guard case let .updatePushNotificationPreferences(_, changes, onCompletion) = action else {
                return
            }
            dispatched.append(changes)
            if dispatched.calls.count == 1 {
                firstCompletion.handler = onCompletion
            } else {
                onCompletion(.success(changes))
            }
        }
        let sut = makeSUT(stores: stores)

        // When the first save (order: true) is in flight, the user flips review on,
        // and then the first save fails.
        sut.setStoreOrderEnabled(true)
        _ = try await wait { firstCompletion.handler != nil }
        sut.setStoreReviewEnabled(true)
        firstCompletion.handler?(.failure(AnyError()))

        // Allow the failure path and the queued save to settle.
        _ = try await wait { dispatched.calls.count >= 2 }
        try await Task.sleep(for: .milliseconds(30))

        // Then the optimistic order value is preserved (no rollback) because a
        // newer edit existed by the time the failure landed, and no error notice
        // is shown for that failed attempt.
        #expect(sut.isStoreOrderEnabled == true)
        #expect(sut.isStoreReviewEnabled == true)
        #expect(sut.errorNotice == nil)
    }

    // MARK: - Flush on dismissal

    @Test func test_flushPendingSaves_dispatches_immediately_bypassing_debounce() async throws {
        // Given a long debounce that would otherwise delay the save.
        let stores = makeStores()
        let dispatched = DispatchedChanges()
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case let .updatePushNotificationPreferences(_, changes, onCompletion) = action {
                dispatched.append(changes)
                onCompletion(.success(changes))
            }
        }
        let sut = makeSUT(stores: stores, debounceDelay: .seconds(5))

        // When
        sut.setStoreOrderEnabled(true)
        sut.flushPendingSaves()

        // Then a dispatch fires well before the debounce window would have elapsed.
        let fired = try await wait(timeout: .milliseconds(500)) { dispatched.calls.count >= 1 }
        #expect(fired)
        #expect(dispatched.last?.storeOrder?.enabled == true)
    }

    @Test func test_flushPendingSaves_while_save_in_flight_skips_redundant_sections() async throws {
        // Given a save is in flight (its completion is held) and the user has
        // since edited a different section.
        let stores = makeStores()
        let dispatched = DispatchedChanges()
        let firstCompletion = PendingCompletion()
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            guard case let .updatePushNotificationPreferences(_, changes, onCompletion) = action else {
                return
            }
            dispatched.append(changes)
            if dispatched.calls.count == 1 {
                firstCompletion.handler = onCompletion
            } else {
                onCompletion(.success(changes))
            }
        }
        let sut = makeSUT(stores: stores)

        // When the first save is in flight and the user flips a different toggle, then dismisses.
        sut.setStoreOrderEnabled(true)
        _ = try await wait { firstCompletion.handler != nil }
        sut.setStoreReviewEnabled(true)
        sut.flushPendingSaves()
        _ = try await wait { dispatched.calls.count >= 2 }

        // Then the flush dispatch carries only the newer section — the in-flight
        // request is left to cover what's already on the wire.
        #expect(dispatched.calls.count == 2)
        #expect(dispatched.calls[1].storeOrder == nil)
        #expect(dispatched.calls[1].storeReview?.enabled == true)
        #expect(dispatched.calls[1].storeStock == nil)

        // Resolve the held first request so the test exits cleanly.
        firstCompletion.handler?(.success(PushNotificationPreferences(storeOrder: .init(enabled: true))))
    }

    @Test func test_flushPendingSaves_when_no_pending_diff_then_no_dispatch() async throws {
        // Given no edits have been made.
        let stores = makeStores()
        let dispatched = DispatchedChanges()
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case let .updatePushNotificationPreferences(_, changes, onCompletion) = action {
                dispatched.append(changes)
                onCompletion(.success(changes))
            }
        }
        let sut = makeSUT(stores: stores)

        // When
        sut.flushPendingSaves()
        try await Task.sleep(for: .milliseconds(50))

        // Then no dispatch ever fires.
        #expect(dispatched.calls.isEmpty)
    }

    // MARK: - Helpers

    /// Polls `condition` until it returns `true` or the timeout elapses. Returns
    /// whether the condition was satisfied. Used in place of fixed `Task.sleep`
    /// calls so tests aren't sensitive to scheduler timing.
    @discardableResult
    private func wait(timeout: Duration = .milliseconds(500),
                      until condition: () -> Bool) async throws -> Bool {
        let deadline = ContinuousClock.now.advanced(by: timeout)
        while !condition() {
            if ContinuousClock.now > deadline {
                return condition()
            }
            try await Task.sleep(for: .milliseconds(5))
        }
        return true
    }
}

/// Reference-typed box for capturing dispatched changes from a closure without `@MainActor` capture issues.
/// Mutations always happen on the main actor in tests; `@unchecked Sendable` is safe.
private final class DispatchedChanges: @unchecked Sendable {
    private(set) var calls: [PushNotificationPreferences] = []
    var last: PushNotificationPreferences? { calls.last }

    func append(_ changes: PushNotificationPreferences) {
        calls.append(changes)
    }
}

/// Reference-typed box to hold a `NotificationAction.updatePushNotificationPreferences`
/// completion closure so it can be resolved later from the test body.
/// Mutations always happen on the main actor in tests; `@unchecked Sendable` is safe.
private final class PendingCompletion: @unchecked Sendable {
    var handler: ((Result<PushNotificationPreferences, Error>) -> Void)?
}

/// Reference-typed box for capturing a held `NotificationAction.loadPushNotificationPreferences`
/// completion handler so the load can be resolved on demand.
private final class PendingLoadCompletion: @unchecked Sendable {
    var handler: ((Result<PushNotificationPreferences, Error>) -> Void)?
}
