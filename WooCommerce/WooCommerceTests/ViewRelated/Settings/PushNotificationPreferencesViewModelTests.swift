import Testing
import Foundation
import Yosemite
import class WooFoundation.CurrencySettings
@testable import WooCommerce

@MainActor
struct PushNotificationPreferencesViewModelTests {

    private let siteID: Int64 = 123

    /// Fixed currency settings for deterministic detail-text formatting in tests.
    /// USD, left-position `$`, no decimals.
    private static let testCurrencySettings = CurrencySettings(currencyCode: .USD,
                                                               currencyPosition: .left,
                                                               thousandSeparator: ",",
                                                               decimalSeparator: ".",
                                                               numberOfDecimals: 0)

    private func makeSUT(stores: MockStoresManager,
                         currencySettings: CurrencySettings = Self.testCurrencySettings) -> PushNotificationPreferencesViewModel {
        PushNotificationPreferencesViewModel(siteID: siteID,
                                             stores: stores,
                                             currencySettings: currencySettings)
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

    // MARK: - discardStoreOrderEdits

    @Test func test_discardStoreOrderEdits_reverts_storeOrder_to_lastSaved_and_clears_unsaved_flag() async {
        // Given a loaded VM with a positive threshold the user then edits.
        let stores = makeStores()
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case let .loadPushNotificationPreferences(_, onCompletion) = action {
                onCompletion(.success(PushNotificationPreferences(storeOrder: .init(enabled: true, minAmount: 100))))
            }
        }
        let sut = makeSUT(stores: stores)
        await sut.load()
        sut.setStoreOrderEnabled(false)
        sut.setStoreOrderMinAmount(500)
        #expect(sut.hasUnsavedChanges == true)

        // When
        sut.discardStoreOrderEdits()

        // Then `displayed.storeOrder` matches the server snapshot again.
        #expect(sut.displayed.storeOrder?.enabled == true)
        #expect(sut.displayed.storeOrder?.minAmount == 100)
        #expect(sut.hasUnsavedChanges == false)
    }

    @Test func test_discardStoreOrderEdits_leaves_other_sections_untouched() async {
        // Given a loaded VM where the user edits review *and* order.
        let stores = makeStores()
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case let .loadPushNotificationPreferences(_, onCompletion) = action {
                onCompletion(.success(PushNotificationPreferences(
                    storeOrder: .init(enabled: true),
                    storeReview: .init(enabled: false)
                )))
            }
        }
        let sut = makeSUT(stores: stores)
        await sut.load()
        sut.setStoreOrderEnabled(false)
        sut.setStoreReviewEnabled(true)

        // When the user discards the order edits.
        sut.discardStoreOrderEdits()

        // Then the review edit is preserved — the discard is scoped to the order section.
        #expect(sut.displayed.storeOrder?.enabled == true)
        #expect(sut.displayed.storeReview?.enabled == true)
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

    @Test func test_isSaving_is_true_while_save_is_in_flight_and_false_after() async {
        // Given
        let stores = makeStores()
        let saveContinuation = SaveContinuationBox()
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case let .updatePushNotificationPreferences(_, changes, onCompletion) = action {
                saveContinuation.deliver = { onCompletion(.success(changes)) }
            }
        }
        let sut = makeSUT(stores: stores)
        sut.setStoreOrderEnabled(true)

        // When
        async let saveResult = sut.save()
        // Yield until `save()` reaches its first await so `isSaving` has flipped.
        await Task.yield()

        // Then
        #expect(sut.isSaving == true)

        // When
        saveContinuation.deliver?()
        _ = await saveResult

        // Then
        #expect(sut.isSaving == false)
    }

    @Test func test_save_is_a_noop_while_another_save_is_already_in_flight() async {
        // Given
        let stores = makeStores()
        let saveContinuation = SaveContinuationBox()
        let dispatched = DispatchedChanges()
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case let .updatePushNotificationPreferences(_, changes, onCompletion) = action {
                dispatched.append(changes)
                saveContinuation.deliver = { onCompletion(.success(changes)) }
            }
        }
        let sut = makeSUT(stores: stores)
        sut.setStoreOrderEnabled(true)
        async let firstSave = sut.save()
        await Task.yield()
        #expect(sut.isSaving == true)

        // When
        let secondSaveResult = await sut.save()

        // Then
        #expect(secondSaveResult == false)
        #expect(dispatched.calls.count == 1)

        saveContinuation.deliver?()
        _ = await firstSave
    }

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

    // MARK: - setStoreOrderMinAmount

    @Test func test_setStoreOrderMinAmount_mutates_displayed_only_and_preserves_enabled() async {
        // Given a loaded VM with the master toggle on.
        let stores = makeStores()
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case let .loadPushNotificationPreferences(_, onCompletion) = action {
                onCompletion(.success(PushNotificationPreferences(storeOrder: .init(enabled: true))))
            }
        }
        let sut = makeSUT(stores: stores)
        await sut.load()

        // When
        sut.setStoreOrderMinAmount(300)

        // Then
        #expect(sut.storeOrderMinAmount == 300)
        #expect(sut.isStoreOrderEnabled == true)
        #expect(sut.hasUnsavedChanges == true)
        #expect(sut.lastKnownStoreOrderMinAmount == 300)
    }

    @Test func test_setStoreOrderMinAmount_with_zero_normalizes_to_nil_and_keeps_lastKnown() async {
        // Given a loaded VM with a positive threshold.
        let stores = makeStores()
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case let .loadPushNotificationPreferences(_, onCompletion) = action {
                onCompletion(.success(PushNotificationPreferences(storeOrder: .init(enabled: true, minAmount: 200))))
            }
        }
        let sut = makeSUT(stores: stores)
        await sut.load()

        // When
        sut.setStoreOrderMinAmount(0)

        // Then
        #expect(sut.storeOrderMinAmount == nil)
        // `lastKnown` keeps the previous positive value so a later restore works.
        #expect(sut.lastKnownStoreOrderMinAmount == 200)
    }

    @Test func test_setStoreOrderMinAmount_with_negative_normalizes_to_nil() async {
        // Given
        let sut = makeSUT(stores: makeStores())

        // When
        sut.setStoreOrderMinAmount(-50)

        // Then
        #expect(sut.storeOrderMinAmount == nil)
    }

    @Test func test_load_when_response_has_positive_minAmount_then_lastKnown_is_populated() async {
        // Given
        let stores = makeStores()
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case let .loadPushNotificationPreferences(_, onCompletion) = action {
                onCompletion(.success(PushNotificationPreferences(storeOrder: .init(enabled: true, minAmount: 250))))
            }
        }
        let sut = makeSUT(stores: stores)

        // When
        await sut.load()

        // Then
        #expect(sut.lastKnownStoreOrderMinAmount == 250)
    }

    // MARK: - storeOrderDetailText

    @Test func test_storeOrderDetailText_when_minAmount_nil_then_returns_all_orders() async {
        // Given
        let sut = makeSUT(stores: makeStores())

        // Then
        #expect(sut.storeOrderDetailText == "All orders")
    }

    @Test func test_storeOrderDetailText_when_minAmount_positive_then_returns_formatted_currency_string() async {
        // Given
        let stores = makeStores()
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case let .loadPushNotificationPreferences(_, onCompletion) = action {
                onCompletion(.success(PushNotificationPreferences(storeOrder: .init(enabled: true, minAmount: 500))))
            }
        }
        let sut = makeSUT(stores: stores)

        // When
        await sut.load()

        // Then
        #expect(sut.storeOrderDetailText == "Orders over $500")
    }

    // MARK: - setStoreReviewMaxRating

    @Test func test_setStoreReviewMaxRating_mutates_displayed_only_and_preserves_enabled() async {
        // Given a loaded VM with the master toggle on.
        let stores = makeStores()
        let dispatched = DispatchedChanges()
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case let .loadPushNotificationPreferences(_, onCompletion) = action {
                onCompletion(.success(PushNotificationPreferences(storeReview: .init(enabled: true))))
            }
            if case let .updatePushNotificationPreferences(_, changes, onCompletion) = action {
                dispatched.append(changes)
                onCompletion(.success(changes))
            }
        }
        let sut = makeSUT(stores: stores)
        await sut.load()

        // When
        sut.setStoreReviewMaxRating(3)

        // Then `displayed` reflects the edit, no dispatch fires yet.
        #expect(sut.storeReviewMaxRating == 3)
        #expect(sut.isStoreReviewEnabled == true)
        #expect(sut.hasUnsavedChanges == true)
        #expect(sut.lastKnownStoreReviewMaxRating == 3)
        #expect(dispatched.calls.isEmpty)
    }

    @Test func test_setStoreReviewMaxRating_above_5_clamps_to_5() async {
        // Given
        let sut = makeSUT(stores: makeStores())

        // When
        sut.setStoreReviewMaxRating(9)

        // Then
        #expect(sut.storeReviewMaxRating == 5)
        #expect(sut.lastKnownStoreReviewMaxRating == 5)
    }

    @Test func test_setStoreReviewMaxRating_below_1_clamps_to_1() async {
        // Given
        let sut = makeSUT(stores: makeStores())

        // When
        sut.setStoreReviewMaxRating(0)

        // Then
        #expect(sut.storeReviewMaxRating == 1)
        #expect(sut.lastKnownStoreReviewMaxRating == 1)
    }

    @Test func test_setStoreReviewMaxRating_with_nil_clears_rating_and_preserves_lastKnown() async {
        // Given a loaded VM with an in-range rating.
        let stores = makeStores()
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case let .loadPushNotificationPreferences(_, onCompletion) = action {
                onCompletion(.success(PushNotificationPreferences(storeReview: .init(enabled: true, maxRating: 4))))
            }
        }
        let sut = makeSUT(stores: stores)
        await sut.load()

        // When
        sut.setStoreReviewMaxRating(nil)

        // Then the rating is cleared but lastKnown still holds the previous value.
        #expect(sut.storeReviewMaxRating == nil)
        #expect(sut.lastKnownStoreReviewMaxRating == 4)
    }

    @Test func test_setStoreReviewEnabled_preserves_existing_maxRating_in_displayed() async {
        // Given a loaded VM with an in-range maxRating.
        let stores = makeStores()
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case let .loadPushNotificationPreferences(_, onCompletion) = action {
                onCompletion(.success(PushNotificationPreferences(storeReview: .init(enabled: true, maxRating: 2))))
            }
        }
        let sut = makeSUT(stores: stores)
        await sut.load()

        // When the user flips the master toggle off.
        sut.setStoreReviewEnabled(false)

        // Then `displayed` retains the rating so a later save preserves it.
        #expect(sut.displayed.storeReview?.enabled == false)
        #expect(sut.displayed.storeReview?.maxRating == 2)
    }

    // MARK: - discardStoreReviewEdits

    @Test func test_discardStoreReviewEdits_reverts_storeReview_to_lastSaved_and_clears_unsaved_flag() async {
        // Given a loaded VM with an in-range rating the user then edits.
        let stores = makeStores()
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case let .loadPushNotificationPreferences(_, onCompletion) = action {
                onCompletion(.success(PushNotificationPreferences(storeReview: .init(enabled: true, maxRating: 4))))
            }
        }
        let sut = makeSUT(stores: stores)
        await sut.load()
        sut.setStoreReviewMaxRating(2)
        #expect(sut.hasUnsavedChanges == true)

        // When
        sut.discardStoreReviewEdits()

        // Then `displayed.storeReview` matches the server snapshot again.
        #expect(sut.displayed.storeReview?.enabled == true)
        #expect(sut.displayed.storeReview?.maxRating == 4)
        #expect(sut.hasUnsavedChanges == false)
    }

    @Test func test_discardStoreReviewEdits_leaves_other_sections_untouched() async {
        // Given a loaded VM where the user edits review *and* order.
        let stores = makeStores()
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case let .loadPushNotificationPreferences(_, onCompletion) = action {
                onCompletion(.success(PushNotificationPreferences(
                    storeOrder: .init(enabled: false),
                    storeReview: .init(enabled: true)
                )))
            }
        }
        let sut = makeSUT(stores: stores)
        await sut.load()
        sut.setStoreOrderEnabled(true)
        sut.setStoreReviewMaxRating(3)

        // When the user discards the review edits.
        sut.discardStoreReviewEdits()

        // Then the order edit is preserved — the discard is scoped to the review section.
        #expect(sut.displayed.storeOrder?.enabled == true)
        #expect(sut.displayed.storeReview?.maxRating == nil)
    }

    @Test func test_load_when_response_has_in_range_maxRating_then_lastKnown_is_populated() async {
        // Given
        let stores = makeStores()
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case let .loadPushNotificationPreferences(_, onCompletion) = action {
                onCompletion(.success(PushNotificationPreferences(storeReview: .init(enabled: true, maxRating: 3))))
            }
        }
        let sut = makeSUT(stores: stores)

        // When
        await sut.load()

        // Then
        #expect(sut.lastKnownStoreReviewMaxRating == 3)
    }

    // MARK: - storeReviewDetailText

    @Test func test_storeReviewDetailText_when_maxRating_nil_then_returns_all_reviews() async {
        // Given
        let sut = makeSUT(stores: makeStores())

        // Then
        #expect(sut.storeReviewDetailText == "All reviews")
    }

    @Test func test_storeReviewDetailText_when_maxRating_is_plural_then_returns_stars_and_below() async {
        // Given
        let stores = makeStores()
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case let .loadPushNotificationPreferences(_, onCompletion) = action {
                onCompletion(.success(PushNotificationPreferences(storeReview: .init(enabled: true, maxRating: 3))))
            }
        }
        let sut = makeSUT(stores: stores)

        // When
        await sut.load()

        // Then
        #expect(sut.storeReviewDetailText == "3 stars and below")
    }

    @Test func test_storeReviewDetailText_when_maxRating_is_one_then_returns_singular_star_phrasing() async {
        // Given
        let stores = makeStores()
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case let .loadPushNotificationPreferences(_, onCompletion) = action {
                onCompletion(.success(PushNotificationPreferences(storeReview: .init(enabled: true, maxRating: 1))))
            }
        }
        let sut = makeSUT(stores: stores)

        // When
        await sut.load()

        // Then
        #expect(sut.storeReviewDetailText == "1 star and below")
    }

    // MARK: - StoreOrderThreshold helpers

    @Test func test_storeOrderThreshold_isAllowedInput_accepts_positive_ascii_integer() {
        #expect(PushNotificationPreferencesViewModel.StoreOrderThreshold.isAllowedInput("5"))
        #expect(PushNotificationPreferencesViewModel.StoreOrderThreshold.isAllowedInput("12345"))
    }

    @Test func test_storeOrderThreshold_isAllowedInput_accepts_non_latin_digits() {
        // Arabic-Indic "500", Eastern Arabic-Indic "500", Devanagari "500".
        #expect(PushNotificationPreferencesViewModel.StoreOrderThreshold.isAllowedInput("\u{0665}\u{0660}\u{0660}"))
        #expect(PushNotificationPreferencesViewModel.StoreOrderThreshold.isAllowedInput("\u{06F5}\u{06F0}\u{06F0}"))
        #expect(PushNotificationPreferencesViewModel.StoreOrderThreshold.isAllowedInput("\u{096B}\u{0966}\u{0966}"))
    }

    @Test func test_storeOrderThreshold_isAllowedInput_rejects_empty_zero_and_leading_zero() {
        #expect(!PushNotificationPreferencesViewModel.StoreOrderThreshold.isAllowedInput(""))
        #expect(!PushNotificationPreferencesViewModel.StoreOrderThreshold.isAllowedInput("0"))
        #expect(!PushNotificationPreferencesViewModel.StoreOrderThreshold.isAllowedInput("00"))
        #expect(!PushNotificationPreferencesViewModel.StoreOrderThreshold.isAllowedInput("01"))
        // Arabic-Indic leading zero (\u{0660} = "٠").
        #expect(!PushNotificationPreferencesViewModel.StoreOrderThreshold.isAllowedInput("\u{0660}\u{0665}"))
    }

    @Test func test_storeOrderThreshold_isAllowedInput_rejects_non_digit_characters() {
        #expect(!PushNotificationPreferencesViewModel.StoreOrderThreshold.isAllowedInput("abc"))
        #expect(!PushNotificationPreferencesViewModel.StoreOrderThreshold.isAllowedInput("1.5"))
        #expect(!PushNotificationPreferencesViewModel.StoreOrderThreshold.isAllowedInput("5e3"))
    }

    @Test func test_storeOrderThreshold_parse_returns_value_for_ascii_and_non_latin_digits() {
        #expect(PushNotificationPreferencesViewModel.StoreOrderThreshold.parse("500") == 500)
        // Arabic-Indic "500" → 500.
        #expect(PushNotificationPreferencesViewModel.StoreOrderThreshold.parse("\u{0665}\u{0660}\u{0660}") == 500)
        // Devanagari "500" → 500.
        #expect(PushNotificationPreferencesViewModel.StoreOrderThreshold.parse("\u{096B}\u{0966}\u{0966}") == 500)
    }

    @Test func test_storeOrderThreshold_parse_returns_nil_for_empty_or_invalid() {
        #expect(PushNotificationPreferencesViewModel.StoreOrderThreshold.parse("") == nil)
        #expect(PushNotificationPreferencesViewModel.StoreOrderThreshold.parse("   ") == nil)
        #expect(PushNotificationPreferencesViewModel.StoreOrderThreshold.parse("abc") == nil)
    }

    @Test func test_storeOrderThreshold_parse_trims_whitespace() {
        #expect(PushNotificationPreferencesViewModel.StoreOrderThreshold.parse("  500  ") == 500)
    }

    @Test func test_storeOrderThreshold_formatInput_returns_ascii_integer_for_positive_amount() {
        #expect(PushNotificationPreferencesViewModel.StoreOrderThreshold.formatInput(100) == "100")
        #expect(PushNotificationPreferencesViewModel.StoreOrderThreshold.formatInput(99999) == "99999")
    }

    @Test func test_storeOrderThreshold_formatInput_returns_empty_for_nil_zero_or_negative() {
        #expect(PushNotificationPreferencesViewModel.StoreOrderThreshold.formatInput(nil).isEmpty)
        #expect(PushNotificationPreferencesViewModel.StoreOrderThreshold.formatInput(0).isEmpty)
        #expect(PushNotificationPreferencesViewModel.StoreOrderThreshold.formatInput(-5).isEmpty)
    }

    // MARK: - storeStock sub-toggles

    @Test func test_setStoreStockLowStock_mutates_displayed_only_and_preserves_siblings() async {
        // Given a loaded VM with all stock sub-fields set so we can prove they're preserved.
        let stores = makeStores()
        let dispatched = DispatchedChanges()
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case let .loadPushNotificationPreferences(_, onCompletion) = action {
                onCompletion(.success(PushNotificationPreferences(storeStock: .init(enabled: true,
                                                                                    lowStock: false,
                                                                                    outOfStock: true,
                                                                                    onBackorder: false))))
            }
            if case let .updatePushNotificationPreferences(_, changes, onCompletion) = action {
                dispatched.append(changes)
                onCompletion(.success(changes))
            }
        }
        let sut = makeSUT(stores: stores)
        await sut.load()

        // When
        sut.setStoreStockLowStock(true)
        await Task.yield()

        // Then
        #expect(sut.isStoreStockLowStock == true)
        #expect(sut.displayed.storeStock?.enabled == true)
        #expect(sut.displayed.storeStock?.outOfStock == true)
        #expect(sut.displayed.storeStock?.onBackorder == false)
        #expect(sut.hasUnsavedChanges == true)
        #expect(dispatched.calls.isEmpty)
    }

    @Test func test_setStoreStockOutOfStock_mutates_displayed_only_and_preserves_siblings() async {
        // Given
        let stores = makeStores()
        let dispatched = DispatchedChanges()
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case let .loadPushNotificationPreferences(_, onCompletion) = action {
                onCompletion(.success(PushNotificationPreferences(storeStock: .init(enabled: true,
                                                                                    lowStock: true,
                                                                                    outOfStock: false,
                                                                                    onBackorder: true))))
            }
            if case let .updatePushNotificationPreferences(_, changes, onCompletion) = action {
                dispatched.append(changes)
                onCompletion(.success(changes))
            }
        }
        let sut = makeSUT(stores: stores)
        await sut.load()

        // When
        sut.setStoreStockOutOfStock(true)
        await Task.yield()

        // Then
        #expect(sut.isStoreStockOutOfStock == true)
        #expect(sut.displayed.storeStock?.enabled == true)
        #expect(sut.displayed.storeStock?.lowStock == true)
        #expect(sut.displayed.storeStock?.onBackorder == true)
        #expect(sut.hasUnsavedChanges == true)
        #expect(dispatched.calls.isEmpty)
    }

    @Test func test_setStoreStockOnBackorder_mutates_displayed_only_and_preserves_siblings() async {
        // Given
        let stores = makeStores()
        let dispatched = DispatchedChanges()
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case let .loadPushNotificationPreferences(_, onCompletion) = action {
                onCompletion(.success(PushNotificationPreferences(storeStock: .init(enabled: true,
                                                                                    lowStock: true,
                                                                                    outOfStock: false,
                                                                                    onBackorder: false))))
            }
            if case let .updatePushNotificationPreferences(_, changes, onCompletion) = action {
                dispatched.append(changes)
                onCompletion(.success(changes))
            }
        }
        let sut = makeSUT(stores: stores)
        await sut.load()

        // When
        sut.setStoreStockOnBackorder(true)
        await Task.yield()

        // Then
        #expect(sut.isStoreStockOnBackorder == true)
        #expect(sut.displayed.storeStock?.enabled == true)
        #expect(sut.displayed.storeStock?.lowStock == true)
        #expect(sut.displayed.storeStock?.outOfStock == false)
        #expect(sut.hasUnsavedChanges == true)
        #expect(dispatched.calls.isEmpty)
    }

    @Test func test_setStoreStockEnabled_preserves_existing_sub_toggles_in_displayed() async {
        // Given a loaded VM with sub-toggles set.
        let stores = makeStores()
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case let .loadPushNotificationPreferences(_, onCompletion) = action {
                onCompletion(.success(PushNotificationPreferences(storeStock: .init(enabled: true,
                                                                                    lowStock: true,
                                                                                    outOfStock: true,
                                                                                    onBackorder: false))))
            }
        }
        let sut = makeSUT(stores: stores)
        await sut.load()

        // When the user flips the master toggle off.
        sut.setStoreStockEnabled(false)

        // Then `displayed` retains the sub-toggle values so a later save preserves them.
        #expect(sut.displayed.storeStock?.enabled == false)
        #expect(sut.displayed.storeStock?.lowStock == true)
        #expect(sut.displayed.storeStock?.outOfStock == true)
        #expect(sut.displayed.storeStock?.onBackorder == false)
    }

    // MARK: - discardStoreStockEdits

    @Test func test_discardStoreStockEdits_reverts_storeStock_to_lastSaved_and_clears_unsaved_flag() async {
        // Given a loaded VM with sub-toggles the user then edits.
        let stores = makeStores()
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case let .loadPushNotificationPreferences(_, onCompletion) = action {
                onCompletion(.success(PushNotificationPreferences(storeStock: .init(enabled: true,
                                                                                    lowStock: true,
                                                                                    outOfStock: true,
                                                                                    onBackorder: true))))
            }
        }
        let sut = makeSUT(stores: stores)
        await sut.load()
        sut.setStoreStockEnabled(false)
        sut.setStoreStockLowStock(false)
        #expect(sut.hasUnsavedChanges == true)

        // When
        sut.discardStoreStockEdits()

        // Then `displayed.storeStock` matches the server snapshot again.
        #expect(sut.displayed.storeStock?.enabled == true)
        #expect(sut.displayed.storeStock?.lowStock == true)
        #expect(sut.displayed.storeStock?.outOfStock == true)
        #expect(sut.displayed.storeStock?.onBackorder == true)
        #expect(sut.hasUnsavedChanges == false)
    }

    @Test func test_discardStoreStockEdits_leaves_other_sections_untouched() async {
        // Given a loaded VM where the user edits stock *and* order.
        let stores = makeStores()
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case let .loadPushNotificationPreferences(_, onCompletion) = action {
                onCompletion(.success(PushNotificationPreferences(
                    storeOrder: .init(enabled: false),
                    storeStock: .init(enabled: true, lowStock: true)
                )))
            }
        }
        let sut = makeSUT(stores: stores)
        await sut.load()
        sut.setStoreOrderEnabled(true)
        sut.setStoreStockLowStock(false)

        // When the user discards the stock edits.
        sut.discardStoreStockEdits()

        // Then the order edit is preserved — the discard is scoped to the stock section.
        #expect(sut.displayed.storeOrder?.enabled == true)
        #expect(sut.displayed.storeStock?.lowStock == true)
    }

    // MARK: - storeStockDetailText

    @Test func test_storeStockDetailText_when_all_three_subtoggles_on_returns_all_stock_alerts() async {
        // Given
        let stores = makeStores()
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case let .loadPushNotificationPreferences(_, onCompletion) = action {
                onCompletion(.success(PushNotificationPreferences(storeStock: .init(enabled: true,
                                                                                    lowStock: true,
                                                                                    outOfStock: true,
                                                                                    onBackorder: true))))
            }
        }
        let sut = makeSUT(stores: stores)

        // When
        await sut.load()

        // Then
        #expect(sut.storeStockDetailText == "All stock alerts")
    }

    @Test func test_storeStockDetailText_when_no_subtoggle_on_returns_no_alerts() async {
        // Given
        let sut = makeSUT(stores: makeStores())

        // Then (no load — sub-toggles default to false)
        #expect(sut.storeStockDetailText == "No alerts")
    }

    @Test func test_storeStockDetailText_when_loaded_with_master_on_and_all_subtoggles_off_returns_no_alerts() async {
        // Given a loaded VM with master on but all three sub-toggles off — the
        // realistic "No alerts" branch that the user sees on the list row.
        let stores = makeStores()
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case let .loadPushNotificationPreferences(_, onCompletion) = action {
                onCompletion(.success(PushNotificationPreferences(storeStock: .init(enabled: true,
                                                                                    lowStock: false,
                                                                                    outOfStock: false,
                                                                                    onBackorder: false))))
            }
        }
        let sut = makeSUT(stores: stores)

        // When
        await sut.load()

        // Then
        #expect(sut.storeStockDetailText == "No alerts")
    }

    @Test func test_storeStockDetailText_when_subset_on_returns_joined_localized_names() async {
        // Given
        let stores = makeStores()
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case let .loadPushNotificationPreferences(_, onCompletion) = action {
                onCompletion(.success(PushNotificationPreferences(storeStock: .init(enabled: true,
                                                                                    lowStock: true,
                                                                                    outOfStock: true,
                                                                                    onBackorder: false))))
            }
        }
        let sut = makeSUT(stores: stores)

        // When
        await sut.load()

        // Then — joined via `ListFormatter`. The exact joiner is locale-dependent,
        // so assert containment of both names rather than the joiner glyph.
        let detail = sut.storeStockDetailText
        #expect(detail.contains("Low stock"))
        #expect(detail.contains("Out of stock"))
        #expect(!detail.contains("On backorder"))
        #expect(detail != "All stock alerts")
        #expect(detail != "No alerts")
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

/// Stashed by the mock store so tests can keep `viewModel.save()` suspended
/// while assertions run, then complete it via `deliver?()`.
private final class SaveContinuationBox: @unchecked Sendable {
    var deliver: (() -> Void)?
}
