import Testing
import Foundation
import Yosemite
@testable import WooCommerce

@MainActor
struct PushNotificationPreferencesViewModelTests {

    private let siteID: Int64 = 123

    private func makeSUT(stores: MockStoresManager) -> PushNotificationPreferencesViewModel {
        PushNotificationPreferencesViewModel(siteID: siteID, stores: stores)
    }

    private func makeStores() -> MockStoresManager {
        MockStoresManager(sessionManager: .testingInstance)
    }

    @Test func test_load_when_remote_succeeds_then_loadState_becomes_loaded_and_toggles_reflect_response() async {
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

    @Test func test_load_when_remote_fails_then_loadState_becomes_error() async {
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

    @Test func test_setStoreOrderEnabled_dispatches_update_with_only_store_order_field() async {
        // Given
        let stores = makeStores()
        let dispatched = DispatchedChanges()
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case let .updatePushNotificationPreferences(_, changes, onCompletion) = action {
                dispatched.value = changes
                onCompletion(.success(changes))
            }
        }
        let sut = makeSUT(stores: stores)

        // When
        sut.setStoreOrderEnabled(true)
        await Task.yield()
        await Task.yield()

        // Then
        #expect(dispatched.value?.storeOrder?.enabled == true)
        #expect(dispatched.value?.storeReview == nil)
        #expect(dispatched.value?.storeStock == nil)
    }

    @Test func test_setStoreReviewEnabled_dispatches_update_with_only_store_review_field() async {
        // Given
        let stores = makeStores()
        let dispatched = DispatchedChanges()
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case let .updatePushNotificationPreferences(_, changes, onCompletion) = action {
                dispatched.value = changes
                onCompletion(.success(changes))
            }
        }
        let sut = makeSUT(stores: stores)

        // When
        sut.setStoreReviewEnabled(true)
        await Task.yield()
        await Task.yield()

        // Then
        #expect(dispatched.value?.storeReview?.enabled == true)
        #expect(dispatched.value?.storeOrder == nil)
        #expect(dispatched.value?.storeStock == nil)
    }

    @Test func test_setStoreStockEnabled_dispatches_update_with_only_store_stock_field() async {
        // Given
        let stores = makeStores()
        let dispatched = DispatchedChanges()
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case let .updatePushNotificationPreferences(_, changes, onCompletion) = action {
                dispatched.value = changes
                onCompletion(.success(changes))
            }
        }
        let sut = makeSUT(stores: stores)

        // When
        sut.setStoreStockEnabled(true)
        await Task.yield()
        await Task.yield()

        // Then
        #expect(dispatched.value?.storeStock?.enabled == true)
        #expect(dispatched.value?.storeOrder == nil)
        #expect(dispatched.value?.storeReview == nil)
    }

    @Test func test_setStoreOrderEnabled_when_remote_fails_then_reverts_optimistic_state_and_surfaces_notice() async {
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
        await Task.yield()
        await Task.yield()

        // Then
        #expect(sut.isStoreOrderEnabled == false)
        #expect(sut.errorNotice != nil)
    }

    @Test func test_setStoreReviewEnabled_when_remote_fails_then_reverts_optimistic_state_and_surfaces_notice() async {
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
        await Task.yield()
        await Task.yield()

        // Then
        #expect(sut.isStoreReviewEnabled == false)
        #expect(sut.errorNotice != nil)
    }

    @Test func test_setStoreStockEnabled_when_remote_fails_then_reverts_optimistic_state_and_surfaces_notice() async {
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
        await Task.yield()
        await Task.yield()

        // Then
        #expect(sut.isStoreStockEnabled == false)
        #expect(sut.errorNotice != nil)
    }

    @Test func test_setStoreOrderEnabled_when_remote_succeeds_then_only_storeOrder_is_applied_from_response() async {
        // Given a server response whose `storeReview` field is stale (false) compared to an
        // in-flight optimistic flip of the review toggle (true). Only the order update is
        // completed; the review update's continuation is held to keep that request in flight.
        let stores = makeStores()
        let staleResponse = PushNotificationPreferences(
            storeOrder: .init(enabled: true),
            storeReview: .init(enabled: false),
            storeStock: .init(enabled: false)
        )
        let pendingReviewCompletion = PendingCompletion()
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            guard case let .updatePushNotificationPreferences(_, changes, onCompletion) = action else {
                return
            }
            if changes.storeOrder != nil {
                onCompletion(.success(staleResponse))
            } else if changes.storeReview != nil {
                pendingReviewCompletion.handler = onCompletion
            }
        }
        let sut = makeSUT(stores: stores)
        sut.setStoreReviewEnabled(true)

        // When the order toggle update succeeds and returns its (stale-for-review) snapshot.
        sut.setStoreOrderEnabled(true)
        await Task.yield()
        await Task.yield()

        // Then the order toggle reflects the server, but the review toggle keeps its
        // optimistic value — it was not part of this request's `changes` payload and its
        // own request hasn't completed yet.
        #expect(sut.isStoreOrderEnabled == true)
        #expect(sut.isStoreReviewEnabled == true)

        // Resolve the dangling continuation so `withCheckedThrowingContinuation` doesn't
        // emit a runtime warning when the test exits.
        pendingReviewCompletion.handler?(.success(staleResponse))
    }
}

/// Reference-typed box for capturing dispatched changes from a closure without `@MainActor` capture issues.
/// Mutations always happen on the main actor in tests; `@unchecked Sendable` is safe.
private final class DispatchedChanges: @unchecked Sendable {
    var value: PushNotificationPreferences?
}

/// Reference-typed box to hold a `NotificationAction.updatePushNotificationPreferences`
/// completion closure so it can be resolved later from the test body.
/// Mutations always happen on the main actor in tests; `@unchecked Sendable` is safe.
private final class PendingCompletion: @unchecked Sendable {
    var handler: ((Result<PushNotificationPreferences, Error>) -> Void)?
}
