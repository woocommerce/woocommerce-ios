import Combine
import Foundation
import Observation
import Yosemite

/// View model backing `PushNotificationPreferencesView`.
///
/// Loads the per-site push notification preferences served by the Woo-driven
/// push system (`wc-push-notifications/preferences`) and writes back partial
/// updates through Yosemite when toggles are flipped.
///
/// Saves are debounced and conflated: rapid edits coalesce into a single
/// network call ~`debounceDelay` after the *last* change. While a save is in
/// flight, further edits collapse to a single follow-up save that fires once
/// the in-flight one completes.
///
@MainActor
@Observable
final class PushNotificationPreferencesViewModel {

    enum LoadState: Equatable {
        case loading
        case loaded
        case error
    }

    private(set) var loadState: LoadState = .loading

    var isStoreOrderEnabled: Bool { displayed?.storeOrder?.enabled ?? false }
    var isStoreReviewEnabled: Bool { displayed?.storeReview?.enabled ?? false }
    var isStoreStockEnabled: Bool { displayed?.storeStock?.enabled ?? false }

    var errorNotice: Notice?

    private let siteID: Int64
    private let stores: StoresManager

    /// Optimistic UI snapshot — what the toggles currently show.
    private var displayed: PushNotificationPreferences?
    /// Last server-confirmed snapshot. The diff against this drives the payload.
    private var lastSaved: PushNotificationPreferences?
    /// Payload that's currently being saved. `nil` when no save is in flight.
    private var inFlight: PushNotificationPreferences?

    private let editSubject = PassthroughSubject<Void, Never>()
    private var subscriptions: Set<AnyCancellable> = []
    /// The currently running save, if any. Drives serialisation: only one
    /// `processSave` runs at a time.
    private var saveTask: Task<Void, Never>?
    /// Set when a save trigger arrives during an in-flight save. Drives the
    /// drop-oldest, conflate follow-up: multiple triggers collapse to one
    /// follow-up save fired after the in-flight one completes.
    private var pendingSaveAfterInFlight = false

    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         debounceDelay: DispatchQueue.SchedulerTimeType.Stride = .seconds(1)) {
        self.siteID = siteID
        self.stores = stores
        editSubject
            .debounce(for: debounceDelay, scheduler: DispatchQueue.main)
            .sink { [weak self] in self?.enqueueSave() }
            .store(in: &subscriptions)
    }

    func load() async {
        loadState = .loading
        do {
            let preferences = try await withCheckedThrowingContinuation { continuation in
                stores.dispatch(NotificationAction.loadPushNotificationPreferences(siteID: siteID) { result in
                    continuation.resume(with: result)
                })
            }
            // Only let fresh server data overwrite the UI when the user has no
            // unsaved edits and nothing is being written. Otherwise the screen
            // would flicker back to the server's view of the world mid-edit.
            if displayed == nil && inFlight == nil {
                displayed = preferences
            }
            lastSaved = preferences
            loadState = .loaded
        } catch {
            DDLogError("⛔️ Error loading push notification preferences for siteID=\(siteID): \(error)")
            loadState = .error
        }
    }

    func setStoreOrderEnabled(_ newValue: Bool) {
        // `StoreOrder` is sent as a complete object (`minAmount: nil` serializes
        // as JSON `null`, which the server interprets as "clear threshold").
        // Preserve the loaded threshold so toggling the master switch doesn't
        // wipe it.
        updateDisplayed { base in
            base.with(storeOrder: .init(enabled: newValue, minAmount: base.storeOrder?.minAmount))
        }
    }

    func setStoreReviewEnabled(_ newValue: Bool) {
        updateDisplayed { base in
            base.with(storeReview: .init(enabled: newValue, maxRating: base.storeReview?.maxRating))
        }
    }

    func setStoreStockEnabled(_ newValue: Bool) {
        updateDisplayed { base in
            let existing = base.storeStock
            return base.with(storeStock: .init(enabled: newValue,
                                               lowStock: existing?.lowStock,
                                               outOfStock: existing?.outOfStock,
                                               onBackorder: existing?.onBackorder))
        }
    }

    /// Flushes any pending unsaved edits immediately, bypassing the debounce.
    ///
    /// Call this when the screen is about to be dismissed. The dispatch is
    /// fire-and-forget — the network request continues even after the view
    /// model is deallocated, since the store retains the completion closure.
    func flushPendingSaves() {
        // Diff against the in-flight snapshot (if any) so we don't re-send
        // sections already on the wire. `inFlight` is always a full snapshot
        // of what was being saved, so it doubles as the post-save baseline.
        guard let displayed,
              case let pendingDiff = makeDiff(from: inFlight ?? lastSaved, to: displayed),
              !pendingDiff.isEmpty else {
            return
        }

        stores.dispatch(NotificationAction.updatePushNotificationPreferences(
            siteID: siteID, changes: pendingDiff) { result in
                if case let .failure(error) = result {
                    DDLogError("⛔️ Error flushing push notification preferences on dismissal: \(error)")
                }
            })
    }
}

private extension PushNotificationPreferencesViewModel {

    /// Updates `displayed` by applying `transform` and pings the debounce
    /// subject so a save fires `debounceDelay` after the last edit.
    func updateDisplayed(_ transform: (PushNotificationPreferences) -> PushNotificationPreferences) {
        let base = displayed ?? lastSaved ?? PushNotificationPreferences()
        displayed = transform(base)
        editSubject.send()
    }

    /// Called when the debounce timer fires. Starts a save if none is running;
    /// otherwise flips a flag so a single follow-up save fires after the
    /// in-flight one completes.
    func enqueueSave() {
        guard saveTask == nil else {
            pendingSaveAfterInFlight = true
            return
        }
        startSave()
    }

    func startSave() {
        saveTask = Task { @MainActor [weak self] in
            await self?.processSave()
            guard let self else { return }
            self.saveTask = nil
            if self.pendingSaveAfterInFlight {
                self.pendingSaveAfterInFlight = false
                self.startSave()
            }
        }
    }

    func processSave() async {
        guard let displayedSnapshot = displayed else { return }
        let pendingDiff = makeDiff(from: lastSaved, to: displayedSnapshot)
        // Empty diff (e.g. on/off within the debounce window) short-circuits
        // before hitting the network.
        guard !pendingDiff.isEmpty else { return }

        inFlight = displayedSnapshot
        let result: Result<PushNotificationPreferences, Error> = await withCheckedContinuation { continuation in
            stores.dispatch(NotificationAction.updatePushNotificationPreferences(
                siteID: siteID, changes: pendingDiff) { result in
                    continuation.resume(returning: result)
                })
        }

        switch result {
        case .success(let server):
            lastSaved = server
            // Only stomp the UI with server data if the user hasn't made newer
            // edits while this request was in flight.
            if displayed == inFlight {
                displayed = server
            }
        case .failure(let error):
            DDLogError("⛔️ Error updating push notification preferences: \(error)")
            // Roll back only when the user hasn't moved on — newer edits must
            // not be stomped by an older request's failure. If no prior save
            // ever succeeded, `lastSaved` is `nil` and `displayed` becomes
            // `nil`, which makes the computed toggles read `false`.
            if displayed == inFlight {
                displayed = lastSaved
                errorNotice = Notice(title: Localization.errorNoticeTitle,
                                     message: Localization.errorNoticeMessage,
                                     feedbackType: .error)
            }
        }
        inFlight = nil
    }

    /// Returns a `PushNotificationPreferences` populated only with sections that
    /// differ between `baseline` and `target`. Comparison is whole-section so
    /// any change inside `storeOrder`/`storeReview`/`storeStock` emits the
    /// section as a complete object (matching the server's section-level merge).
    func makeDiff(from baseline: PushNotificationPreferences?,
                  to target: PushNotificationPreferences) -> PushNotificationPreferences {
        PushNotificationPreferences(
            storeOrder: target.storeOrder != baseline?.storeOrder ? target.storeOrder : nil,
            storeReview: target.storeReview != baseline?.storeReview ? target.storeReview : nil,
            storeStock: target.storeStock != baseline?.storeStock ? target.storeStock : nil
        )
    }
}

private extension PushNotificationPreferences {
    var isEmpty: Bool {
        storeOrder == nil && storeReview == nil && storeStock == nil
    }

    func with(storeOrder: StoreOrder) -> Self {
        .init(storeOrder: storeOrder, storeReview: storeReview, storeStock: storeStock)
    }

    func with(storeReview: StoreReview) -> Self {
        .init(storeOrder: storeOrder, storeReview: storeReview, storeStock: storeStock)
    }

    func with(storeStock: StoreStock) -> Self {
        .init(storeOrder: storeOrder, storeReview: storeReview, storeStock: storeStock)
    }
}

extension PushNotificationPreferencesViewModel {
    enum Localization {
        static let errorNoticeTitle = NSLocalizedString(
            "pushNotificationPreferencesViewModel.errorNoticeTitle",
            value: "Couldn't update notification preferences",
            comment: "Title of the notice shown when updating push notification preferences fails."
        )
        static let errorNoticeMessage = NSLocalizedString(
            "pushNotificationPreferencesViewModel.errorNoticeMessage",
            value: "Please try again.",
            comment: "Message of the notice shown when updating push notification preferences fails."
        )
    }
}
