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

    // MARK: - Loading

    @Test func test_load_when_remote_succeeds_then_loadState_becomes_loaded_and_displayed_lastSaved_reflect_response() async {
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
        #expect(sut.hasUnsavedChanges == false)
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

    @Test func test_load_when_unsaved_edits_exist_then_response_does_not_stomp_displayed_state() async {
        // Given the user has flipped a toggle (creating an unsaved edit) before a fresh load.
        let stores = makeStores()
        let response = PushNotificationPreferences(storeOrder: .init(enabled: false))
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case let .loadPushNotificationPreferences(_, onCompletion) = action {
                onCompletion(.success(response))
            }
        }
        let sut = makeSUT(stores: stores)
        sut.setStoreOrderEnabled(true)

        // When the load returns with `enabled: false`.
        await sut.load()

        // Then the optimistic edit is preserved on `displayed`, but `lastSaved`
        // tracks the server snapshot so the next save still diffs correctly.
        #expect(sut.isStoreOrderEnabled == true)
        #expect(sut.hasUnsavedChanges == true)
    }

    // MARK: - Setters mutate displayed only

    @Test func test_setStoreOrderEnabled_mutates_displayed_only_and_does_not_dispatch_update() async {
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
        await Task.yield()

        // Then
        #expect(sut.isStoreOrderEnabled == true)
        #expect(sut.hasUnsavedChanges == true)
        #expect(dispatched.calls.isEmpty)
    }

    @Test func test_setStoreReviewEnabled_mutates_displayed_only_and_does_not_dispatch_update() async {
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
        await Task.yield()

        // Then
        #expect(sut.isStoreReviewEnabled == true)
        #expect(sut.hasUnsavedChanges == true)
        #expect(dispatched.calls.isEmpty)
    }

    @Test func test_setStoreStockEnabled_mutates_displayed_only_and_does_not_dispatch_update() async {
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
        await Task.yield()

        // Then
        #expect(sut.isStoreStockEnabled == true)
        #expect(sut.hasUnsavedChanges == true)
        #expect(dispatched.calls.isEmpty)
    }

    @Test func test_setStoreOrderEnabled_preserves_existing_minAmount_in_displayed() async {
        // Given a loaded VM with a positive threshold.
        let stores = makeStores()
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case let .loadPushNotificationPreferences(_, onCompletion) = action {
                onCompletion(.success(PushNotificationPreferences(storeOrder: .init(enabled: true, minAmount: 100))))
            }
        }
        let sut = makeSUT(stores: stores)
        await sut.load()

        // When the user flips the master toggle off.
        sut.setStoreOrderEnabled(false)

        // Then `displayed` retains the threshold so a later save preserves it.
        #expect(sut.displayed.storeOrder?.enabled == false)
        #expect(sut.displayed.storeOrder?.minAmount == 100)
    }

    // MARK: - hasUnsavedChanges

    @Test func test_hasUnsavedChanges_when_displayed_equals_lastSaved_then_false() async {
        // Given a loaded VM with no edits.
        let stores = makeStores()
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case let .loadPushNotificationPreferences(_, onCompletion) = action {
                onCompletion(.success(PushNotificationPreferences(storeOrder: .init(enabled: true))))
            }
        }
        let sut = makeSUT(stores: stores)
        await sut.load()

        // Then
        #expect(sut.hasUnsavedChanges == false)
    }

    @Test func test_hasUnsavedChanges_when_displayed_differs_then_true() async {
        // Given
        let sut = makeSUT(stores: makeStores())

        // When
        sut.setStoreOrderEnabled(true)

        // Then
        #expect(sut.hasUnsavedChanges == true)
    }

    @Test func test_hasUnsavedChanges_when_toggle_flipped_back_to_lastSaved_then_false() async {
        // Given a loaded VM with `enabled: true`.
        let stores = makeStores()
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case let .loadPushNotificationPreferences(_, onCompletion) = action {
                onCompletion(.success(PushNotificationPreferences(storeOrder: .init(enabled: true))))
            }
        }
        let sut = makeSUT(stores: stores)
        await sut.load()

        // When the user toggles off then back on.
        sut.setStoreOrderEnabled(false)
        sut.setStoreOrderEnabled(true)

        // Then `displayed` equals `lastSaved` again — no diff to save.
        #expect(sut.hasUnsavedChanges == false)
    }

    // MARK: - Save

    @Test func test_save_when_remote_succeeds_then_lastSaved_updates_and_returns_true() async {
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
        sut.setStoreOrderEnabled(true)
        #expect(sut.hasUnsavedChanges == true)

        // When
        let success = await sut.save()

        // Then
        #expect(success == true)
        #expect(sut.hasUnsavedChanges == false)
        #expect(dispatched.last?.storeOrder?.enabled == true)
        #expect(dispatched.last?.storeReview == nil)
        #expect(dispatched.last?.storeStock == nil)
    }

    @Test func test_save_when_remote_fails_then_returns_false_and_surfaces_notice() async {
        // Given
        struct AnyError: Error {}
        let stores = makeStores()
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case let .updatePushNotificationPreferences(_, _, onCompletion) = action {
                onCompletion(.failure(AnyError()))
            }
        }
        let sut = makeSUT(stores: stores)
        sut.setStoreOrderEnabled(true)

        // When
        let success = await sut.save()

        // Then
        #expect(success == false)
        #expect(sut.errorNotice != nil)
        // `displayed` preserved so the user can retry; still unsaved.
        #expect(sut.isStoreOrderEnabled == true)
        #expect(sut.hasUnsavedChanges == true)
    }

    @Test func test_save_with_no_pending_changes_then_returns_true_without_dispatch() async {
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
        let success = await sut.save()

        // Then
        #expect(success == true)
        #expect(dispatched.calls.isEmpty)
    }

    @Test func test_save_dispatches_only_changed_sections() async {
        // Given a loaded VM with one section edited.
        let stores = makeStores()
        let dispatched = DispatchedChanges()
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case let .loadPushNotificationPreferences(_, onCompletion) = action {
                onCompletion(.success(PushNotificationPreferences(
                    storeOrder: .init(enabled: false),
                    storeReview: .init(enabled: false),
                    storeStock: .init(enabled: false)
                )))
            }
            if case let .updatePushNotificationPreferences(_, changes, onCompletion) = action {
                dispatched.append(changes)
                onCompletion(.success(PushNotificationPreferences(
                    storeOrder: .init(enabled: true),
                    storeReview: .init(enabled: false),
                    storeStock: .init(enabled: false)
                )))
            }
        }
        let sut = makeSUT(stores: stores)
        await sut.load()

        // When only the order section is edited.
        sut.setStoreOrderEnabled(true)
        let success = await sut.save()

        // Then the diff carries only the order section.
        #expect(success == true)
        #expect(dispatched.last?.storeOrder?.enabled == true)
        #expect(dispatched.last?.storeReview == nil)
        #expect(dispatched.last?.storeStock == nil)
    }
}

/// Reference-typed box for capturing dispatched changes from a closure without
/// `@MainActor` capture issues. Mutations happen on the main actor in tests; the
/// `@unchecked Sendable` annotation is safe in that context.
private final class DispatchedChanges: @unchecked Sendable {
    private(set) var calls: [PushNotificationPreferences] = []
    var last: PushNotificationPreferences? { calls.last }

    func append(_ changes: PushNotificationPreferences) {
        calls.append(changes)
    }
}
